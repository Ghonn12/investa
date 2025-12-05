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

    private function getLoggedInUserId() {
        $key = getenv('JWT_SECRET');
        $header = $this->request->getHeaderLine('Authorization');
        if (!empty($header) && preg_match('/Bearer\s(\S+)/', $header, $matches)) {
            try {
                $decoded = JWT::decode($matches[1], new Key($key, 'HS256'));
                return $decoded->uid;
            } catch (Exception $e) { return null; }
        }
        return null;
    }

    public function summary() {
        $userId = $this->getLoggedInUserId();
        if(!$userId) return $this->failUnauthorized();

        $transaksiModel = new TransaksiModel();
        $walletModel = new WalletModel();

        // 1. Rekap Kategori (Untuk Pie Chart)
        $pengeluaranKategori = $transaksiModel
            ->select('categories.nama_kategori, SUM(transactions.amount) as total')
            ->join('categories', 'categories.id = transactions.category_id')
            ->where('transactions.user_id', $userId)
            ->where('transactions.type', 'Pengeluaran') // atau EXPENSE
            ->where('MONTH(transactions.date)', date('m'))
            ->where('YEAR(transactions.date)', date('Y'))
            ->groupBy('categories.nama_kategori')
            ->findAll();

        // 2. Rekap Saldo Wallet
        $wallets = $walletModel->where('user_id', $userId)->findAll();
        $saldoPerWallet = [];

        foreach ($wallets as $wallet) {
            $pemasukan = $transaksiModel
                ->where('user_id', $userId)
                ->where('wallet_id', $wallet['id'])
                ->where('type', 'Pemasukan')
                ->selectSum('amount')->get()->getRow()->amount ?? 0;

            $pengeluaran = $transaksiModel
                ->where('user_id', $userId)
                ->where('wallet_id', $wallet['id'])
                ->where('type', 'Pengeluaran')
                ->selectSum('amount')->get()->getRow()->amount ?? 0;
            
            $saldoPerWallet[] = [
                'nama' => $wallet['nama_wallet'],
                'saldo' => $pemasukan - $pengeluaran
            ];
        }

        return $this->respond([
            'success' => true,
            'data' => [
                'saldo_per_wallet' => $saldoPerWallet,
                'pengeluaran_per_kategori' => $pengeluaranKategori
            ]
        ]);
    }
}