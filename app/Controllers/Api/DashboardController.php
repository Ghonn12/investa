<?php namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\API\ResponseTrait;
use App\Models\TransaksiModel;
use App\Models\WalletModel;
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;
use \Exception;

class DashboardController extends ResourceController
{
    use ResponseTrait;

    public function summary() {
        $userId = $this->request->user_id;

        $transaksiModel = new TransaksiModel();
        $walletModel = new WalletModel();

        // 1. Rekap Kategori (Untuk Pie Chart - Pengeluaran Bulan Ini)
        $pengeluaranKategori = $transaksiModel
            ->select('categories.nama_kategori, SUM(transactions.amount) as total')
            ->join('categories', 'categories.id = transactions.category_id')
            ->where('transactions.user_id', $userId)
            ->where('transactions.type', 'Pengeluaran') 
            ->where('MONTH(transactions.date)', date('m'))
            ->where('YEAR(transactions.date)', date('Y'))
            ->groupBy('categories.nama_kategori')
            ->findAll();

        // 2. Hitung Saldo Tiap Wallet
        $wallets = $walletModel->where('user_id', $userId)->findAll();
        
        $totalCash = 0;
        $totalRekening = 0;

        foreach ($wallets as $wallet) {
            // Hitung Income
            $pemasukan = $transaksiModel
                ->where('user_id', $userId)
                ->where('wallet_id', $wallet['id'])
                ->groupStart() // (Pemasukan OR INCOME)
                    ->where('type', 'Pemasukan')
                    ->orWhere('type', 'INCOME')
                ->groupEnd()
                ->selectSum('amount')->get()->getRow()->amount ?? 0;

            // Hitung Expense
            $pengeluaran = $transaksiModel
                ->where('user_id', $userId)
                ->where('wallet_id', $wallet['id'])
                ->groupStart() 
                    ->where('type', 'Pengeluaran')
                    ->orWhere('type', 'EXPENSE')
                    ->orWhere('type', 'Penarikan') // Support Penarikan as Expense
                ->groupEnd()
                ->selectSum('amount')->get()->getRow()->amount ?? 0;
            
            $saldo = $pemasukan - $pengeluaran;

            // Klasifikasi Cash vs Rekening
            // Kita asumsikan jika nama wallet mengandung 'Cash' atau tipe 'Cash'
            $isCash = stripos($wallet['nama_wallet'], 'Cash') !== false || stripos($wallet['tipe_wallet'], 'Cash') !== false;

            if ($isCash) {
                $totalCash += $saldo;
            } else {
                $totalRekening += $saldo;
            }
        }

        return $this->respond([
            'success' => true,
            'data' => [
                'total_cash' => $totalCash,
                'total_rekening' => $totalRekening,
                'pie_chart' => $pengeluaranKategori
            ]
        ]);
    }
}