<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\PortfolioModel;
// use App\Models\UserModel; // Removed dependency on global user balance
use App\Libraries\MarketService;
use App\Models\WalletModel;
use App\Models\TransaksiModel;

class TradeController extends ApiController
{
    // GET: Lihat Portfolio dengan Profit/Loss Realtime
    public function portfolio()
    {
        $userId = $this->request->user_id;
        $model = new PortfolioModel();
        $portfolios = $model->where('user_id', $userId)->findAll();
        
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
        
        // Hitung Total Cash Balance dari Transaksi
        $cashBalance = $this->getUserCashBalance($userId);
        
        return $this->success([
            'cash_balance' => $cashBalance,
            'portfolio_value' => $totalPortfolioValue,
            'net_worth' => $cashBalance + $totalPortfolioValue,
            'holdings' => $enrichedData
        ]);
    }

    // POST: Beli Saham (Buy)
    public function buy()
    {
        $rules = [
            'symbol' => 'required', 
            'quantity' => 'required|numeric|greater_than[0]',
            'wallet_id' => 'required|numeric' // New Requirement
        ];
        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qty = (float)$this->request->getVar('quantity');
        $walletId = $this->request->getVar('wallet_id');
        $userId = $this->request->user_id;

        // 1. Validasi Wallet Milik User
        $walletModel = new WalletModel();
        $wallet = $walletModel->where('id', $walletId)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->error("Wallet tidak ditemukan atau bukan milik Anda.");
        }

        // 2. Hitung Saldo Wallet (Dynamic Calculation)
        $currentBalance = $this->getWalletBalance($userId, $walletId);

        // 3. Ambil Harga Pasar
        $marketService = new MarketService();
        $currentPrice = $marketService->getPrice($symbol);

        if (!$currentPrice) {
            return $this->error("Gagal mengambil harga pasar untuk simbol: $symbol.", 400);
        }

        $totalCost = $currentPrice * $qty;

        if ($currentBalance < $totalCost) {
            return $this->error("Saldo Wallet tidak cukup. Butuh: " . number_format($totalCost, 0) . ", Ada: " . number_format($currentBalance, 0));
        }

        $portfolioModel = new PortfolioModel();
        $trxModel = new TransaksiModel();
        
        $db = \Config\Database::connect();
        $db->transStart();

        try {
            // A. Catat Transaksi Pengeluaran (Investasi)
            $trxModel->insert([
                'user_id' => $userId,
                'wallet_id' => $walletId,
                'category_id' => null, // Atau set ID kategori Investasi jika ada
                'amount' => $totalCost,
                'type' => 'Pengeluaran', // Mengurangi saldo wallet
                'title' => "Beli Saham $symbol",
                'deskripsi' => "Investasi $symbol x $qty lembar @ $currentPrice",
                'date' => date('Y-m-d H:i:s')
            ]);

            // B. Update Portfolio (Average Down)
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
                'wallet_remaining_balance' => $currentBalance - $totalCost
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
            'quantity' => 'required|numeric|greater_than[0]',
            'wallet_id' => 'required|numeric' // New: Uang hasil jual masuk ke wallet mana?
        ];
        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qtyToSell = (float)$this->request->getVar('quantity');
        $walletId = $this->request->getVar('wallet_id');
        $userId = $this->request->user_id;

        // Validasi Wallet
        $walletModel = new WalletModel();
        $wallet = $walletModel->where('id', $walletId)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->error("Wallet tidak ditemukan.");
        }

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
             return $this->error("Gagal mengambil harga pasar saat ini. Transaksi dibatalkan.");
        }

        // 4. Hitung Penerimaan (Revenue)
        $totalRevenue = $currentPrice * $qtyToSell;

        $trxModel = new TransaksiModel();
        $db = \Config\Database::connect();
        $db->transStart();

        try {
            // A. Catat Transaksi Pemasukan (Divestasi/Profit) ke Wallet
            $trxModel->insert([
                'user_id' => $userId,
                'wallet_id' => $walletId,
                'category_id' => null,
                'amount' => $totalRevenue,
                'type' => 'Pemasukan', // Menambah saldo wallet
                'title' => "Jual Saham $symbol",
                'deskripsi' => "Jual $symbol x $qtyToSell lembar @ $currentPrice",
                'date' => date('Y-m-d H:i:s')
            ]);

            // B. Update Portfolio
            $remainingQty = $currentQty - $qtyToSell;

            if ($remainingQty <= 0) {
                // Jika habis, hapus baris dari tabel
                $portfolioModel->delete($existing['id']);
            } else {
                // Jika masih ada sisa, update quantity saja
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
            $price = $marketService->getPrice($symbol);
            
            $stockData[] = [
                'symbol' => $symbol,
                'name'   => $this->getCompanyName($symbol), 
                'price'  => $price,
            ];
        }

        return $this->success($stockData);
    }

    // Helper sederhana untuk nama perusahaan
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

    // Helper: Hitung Total Cash User (Sum Semua Wallet)
    private function getUserCashBalance($userId) {
        $trxModel = new TransaksiModel();

        // Sum Income
        $pemasukan = $trxModel
            ->where('user_id', $userId)
            ->groupStart()
                ->where('type', 'Pemasukan')
                ->orWhere('type', 'INCOME')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        // Sum Expense
        $pengeluaran = $trxModel
            ->where('user_id', $userId)
            ->groupStart() 
                ->where('type', 'Pengeluaran')
                ->orWhere('type', 'EXPENSE')
                ->orWhere('type', 'Penarikan')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        return $pemasukan - $pengeluaran;
    }

    // Private Helper: Calculate Wallet Balance Dynamically
    private function getWalletBalance($userId, $walletId) {
        $trxModel = new TransaksiModel();

        // Sum Income
        $pemasukan = $trxModel
            ->where('user_id', $userId)
            ->where('wallet_id', $walletId)
            ->groupStart()
                ->where('type', 'Pemasukan')
                ->orWhere('type', 'INCOME')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        // Sum Expense
        $pengeluaran = $trxModel
            ->where('user_id', $userId)
            ->where('wallet_id', $walletId)
            ->groupStart() 
                ->where('type', 'Pengeluaran')
                ->orWhere('type', 'EXPENSE')
                ->orWhere('type', 'Penarikan')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        return $pemasukan - $pengeluaran;
    }
}
