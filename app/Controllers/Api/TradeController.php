<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\PortfolioModel;
use App\Models\UserModel;
use App\Libraries\MarketService;

class TradeController extends ApiController
{
    // GET: Lihat Portfolio dengan Profit/Loss Realtime
    public function portfolio()
    {
        $userId = $this->request->user_id;
        $model = new PortfolioModel();
        $portfolios = $model->where('user_id', $userId)->findAll();
        
        $userModel = new UserModel();
        $user = $userModel->find($userId);

        $marketService = new MarketService();
        $enrichedData = [];
        $totalPortfolioValue = 0;

        foreach ($portfolios as $item) {
            // 1. Ambil harga pasar terbaru
            $currentPrice = $marketService->getPrice($item['symbol']);
            if (!$currentPrice) {
                $currentPrice = (float)$item['average_price'];
            }

            // 2. Hitung Profit/Loss
            $qty = (float)$item['quantity'];
            $avgPrice = (float)$item['average_price'];

            $currentValue = $qty * $currentPrice;
            $investmentValue = $qty * $avgPrice;
            
            $pnl = $currentValue - $investmentValue;
            
            $pnlPercent = ($investmentValue > 0) ? ($pnl / $investmentValue) * 100 : 0;

            $totalPortfolioValue += $currentValue;

            $enrichedData[] = [
                'id' => $item['id'],
                'symbol' => $item['symbol'],
                'quantity' => $qty,
                'average_price' => $avgPrice,
                'current_price' => $currentPrice,
                'current_value' => $currentValue,
                'pnl' => $pnl,
                'pnl_percent' => round($pnlPercent, 2)
            ];
        }
        
        return $this->success([
            'cash_balance' => (float)$user['balance'],
            'portfolio_value' => $totalPortfolioValue,
            'net_worth' => (float)$user['balance'] + $totalPortfolioValue,
            'holdings' => $enrichedData
        ]);
    }

    // POST: Beli Saham (Buy)
    public function buy()
    {
        $rules = [
            'symbol' => 'required', 
            'quantity' => 'required|numeric'
        ];
        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qty = (float)$this->request->getVar('quantity');
        $userId = $this->request->user_id;

        $marketService = new MarketService();
        $currentPrice = $marketService->getPrice($symbol);

        if (!$currentPrice) {
            return $this->error("Gagal mengambil harga pasar untuk simbol: $symbol.", 400);
        }

        $totalCost = $currentPrice * $qty;

        $userModel = new UserModel();
        $portfolioModel = new PortfolioModel();
        
        $db = \Config\Database::connect();
        $db->transStart();

        try {
            $user = $userModel->find($userId);
            if ((float)$user['balance'] < $totalCost) {
                return $this->error("Saldo tidak cukup. Butuh: $totalCost, Punya: {$user['balance']}");
            }

            // Kurangi Saldo
            $userModel->update($userId, ['balance' => (float)$user['balance'] - $totalCost]);

            // Update Portfolio (Average Down)
            $existing = $portfolioModel->where('user_id', $userId)->where('symbol', $symbol)->first();

            if ($existing) {
                $oldQty = (float)$existing['quantity'];
                $oldAvg = (float)$existing['average_price'];
                
                $newTotalQty = $oldQty + $qty;
                $newAvgPrice = (($oldQty * $oldAvg) + ($qty * $currentPrice)) / $newTotalQty;

                $portfolioModel->update($existing['id'], [
                    'quantity' => $newTotalQty,
                    'average_price' => $newAvgPrice
                ]);
            } else {
                $portfolioModel->insert([
                    'user_id' => $userId,
                    'symbol' => $symbol,
                    'quantity' => $qty,
                    'average_price' => $currentPrice
                ]);
            }

            $db->transComplete();

            return $this->success([
                'symbol' => $symbol,
                'quantity_bought' => $qty,
                'price' => $currentPrice,
                'total_cost' => $totalCost,
                'remaining_balance' => (float)$user['balance'] - $totalCost
            ], "Berhasil membeli $symbol");

        } catch (\Exception $e) {
            $db->transRollback();
            return $this->error($e->getMessage(), 500);
        }
    }

    // POST: Jual Saham (Sell)
    public function sell()
    {
        // 1. Validasi
        $rules = [
            'symbol' => 'required',
            'quantity' => 'required|numeric'
        ];
        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qtyToSell = (float)$this->request->getVar('quantity');
        $userId = $this->request->user_id;

        // 2. Cek apakah User punya asetnya
        $portfolioModel = new PortfolioModel();
        $existing = $portfolioModel->where('user_id', $userId)->where('symbol', $symbol)->first();

        if (!$existing) {
            return $this->error("Anda tidak memiliki aset $symbol");
        }

        $currentQty = (float)$existing['quantity'];
        if ($currentQty < $qtyToSell) {
            return $this->error("Jumlah aset tidak cukup. Punya: $currentQty, Ingin Jual: $qtyToSell");
        }

        // 3. Cek Harga Pasar
        $marketService = new MarketService();
        $currentPrice = $marketService->getPrice($symbol);
        
        if (!$currentPrice) {
             // Jika gagal ambil harga, gagalkan transaksi agar aman
             return $this->error("Gagal mengambil harga pasar saat ini. Transaksi dibatalkan.");
        }

        // 4. Hitung Penerimaan (Revenue)
        $totalRevenue = $currentPrice * $qtyToSell;

        $userModel = new UserModel();
        $db = \Config\Database::connect();
        $db->transStart();

        try {
            // A. Tambah Saldo User
            $user = $userModel->find($userId);
            $newBalance = (float)$user['balance'] + $totalRevenue;
            $userModel->update($userId, ['balance' => $newBalance]);

            // B. Update Portfolio
            $remainingQty = $currentQty - $qtyToSell;

            if ($remainingQty <= 0) {
                // Jika habis, hapus baris dari tabel
                $portfolioModel->delete($existing['id']);
            } else {
                // Jika masih ada sisa, update quantity saja
                // PENTING: Saat Jual, Average Price TIDAK BERUBAH
                $portfolioModel->update($existing['id'], [
                    'quantity' => $remainingQty
                ]);
            }

            $db->transComplete();

            return $this->success([
                'symbol' => $symbol,
                'quantity_sold' => $qtyToSell,
                'price_at_sell' => $currentPrice,
                'total_revenue' => $totalRevenue,
                'new_balance' => $newBalance
            ], "Berhasil menjual $symbol");

        } catch (\Exception $e) {
            $db->transRollback();
            return $this->error($e->getMessage(), 500);
        }
    }
    public function getPrice()
    {
        $symbol = strtoupper($this->request->getVar('symbol'));
        
        if (!$symbol) {
            return $this->error("Parameter 'symbol' wajib diisi", 400);
        }

        $marketService = new MarketService();
        $price = $marketService->getPrice($symbol);

        if (!$price) {
            return $this->error("Gagal mengambil harga untuk $symbol", 404);
        }

        return $this->success([
            'symbol' => $symbol,
            'price' => $price,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    }
    public function getMarketStocks()
    {
        // Daftar simbol saham populer yang ingin ditampilkan
        $symbols = [
            'BBCA.JK', 'TLKM.JK', 'BBRI.JK', 'BMRI.JK', 
            'ASII.JK', 'GOTO.JK', 'BTC-USD', 'ETH-USD'
        ];

        $marketService = new MarketService();
        $stockData = [];

        foreach ($symbols as $symbol) {
            // Panggil MarketService untuk setiap simbol
            // (Idealnya ini di-cache atau di-batch request jika API mendukung, tapi untuk sekarang loop ok)
            $price = $marketService->getPrice($symbol);
            
            $stockData[] = [
                'symbol' => $symbol,
                'name'   => $this->getCompanyName($symbol), // Helper function sederhana
                'price'  => $price,
                // 'change' => ... (bisa ditambahkan jika MarketService support)
            ];
        }

        return $this->success($stockData);
    }

    // Helper sederhana untuk nama perusahaan (bisa dipindah ke Model/Config)
    private function getCompanyName($symbol) {
        $names = [
            'BBCA.JK' => 'Bank Central Asia',
            'TLKM.JK' => 'Telkom Indonesia',
            'BBRI.JK' => 'Bank Rakyat Indonesia',
            'BMRI.JK' => 'Bank Mandiri',
            'ASII.JK' => 'Astra International',
            'GOTO.JK' => 'GoTo Gojek Tokopedia',
            'BTC-USD' => 'Bitcoin',
            'ETH-USD' => 'Ethereum'
        ];
        return $names[$symbol] ?? $symbol;
    }
}
