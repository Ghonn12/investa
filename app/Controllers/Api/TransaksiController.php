<?php namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\API\ResponseTrait;
use App\Models\TransaksiModel;

class TransaksiController extends ResourceController
{
    use ResponseTrait;
    protected $modelName = 'App\Models\TransaksiModel';
    protected $format    = 'json';

    public function index() {
        $userId = $this->request->user_id;

        $data = $this->model
            ->select('transactions.*, categories.nama_kategori, wallets.nama_wallet')
            ->join('categories', 'categories.id = transactions.category_id', 'left')
            ->join('wallets', 'wallets.id = transactions.wallet_id', 'left')
            ->where('transactions.user_id', $userId)
            ->orderBy('transactions.date', 'DESC')
            ->orderBy('transactions.id', 'DESC')
            ->findAll();
        
        return $this->respond(['success' => true, 'data' => $data]);
    }

    public function create() {
        $userId = $this->request->user_id;
        $data = $this->request->getPost();
        $data['user_id'] = $userId;
        $data['title'] = $data['deskripsi'] ?? 'Transaksi Baru'; 
        
        // LOGIC PENARIKAN (TRANSFER REKENING -> CASH)
        if (isset($data['type']) && $data['type'] === 'Penarikan') {
            
            // 1. Cari Wallet Cash Tunai milik user
            // Prioritaskan 'tipe_wallet' = 'Cash' agar lebih robust
            $walletModel = new \App\Models\WalletModel();
            
            $cashWallet = $walletModel
                ->where('user_id', $userId)
                ->where('tipe_wallet', 'Cash')
                ->first();

            // Jika tidak ketemu berdasarkan tipe, baru coba cari berdasarkan nama (fallback legacy)
            if (!$cashWallet) {
                $cashWallet = $walletModel
                    ->where('user_id', $userId)
                    ->groupStart()
                        ->like('nama_wallet', 'Cash')
                        ->orLike('nama_wallet', 'Tunai')
                    ->groupEnd()
                    ->first();
            }

            // Jika belum punya wallet Cash, buatkan otomatis? Atau error?
            // Untuk user experience, kita buatkan saja jika belum ada.
            if (!$cashWallet) {
                $walletModel->insert([
                    'user_id' => $userId,
                    'nama_wallet' => 'Cash Tunai',
                    'tipe_wallet' => 'Cash',
                    'saldo' => 0
                ]);
                $cashWallet = $walletModel->where('id', $walletModel->getInsertID())->first();
            }

            // 2. Buat Transaksi PENGELUARAN dari Wallet Asal (Rekening)
            $expenseData = [
                'user_id' => $userId,
                'wallet_id' => $data['wallet_id'], // Wallet yg dipilih user
                'category_id' => null, // Penarikan tidak butuh kategori atau bisa set kategori khusus
                'amount' => $data['amount'],
                'date' => $data['date'],
                'type' => 'Pengeluaran', // Tetap dicatat sebagai pengeluaran di wallet asal
                'title' => 'Tarik Uang (Penarikan)',
                'deskripsi' => $data['deskripsi'] . ' (Source)',
            ];
            $this->model->insert($expenseData);

            // 3. Buat Transaksi PEMASUKAN ke Wallet Tujuan (Cash)
            $incomeData = [
                'user_id' => $userId,
                'wallet_id' => $cashWallet['id'],
                'category_id' => null, 
                'amount' => $data['amount'],
                'date' => $data['date'],
                'type' => 'Pemasukan',
                'title' => 'Setor Tunai (Penarikan)',
                'deskripsi' => $data['deskripsi'] . ' (Dest)',
            ];
            $this->model->insert($incomeData);
            
            return $this->respondCreated(['success' => true, 'message' => 'Penarikan Berhasil']);
        }

        // Logic Standard (Pemasukan/Pengeluaran Biasa)
        if($this->model->insert($data) === false) {
             return $this->fail($this->model->errors());
        }
        
        return $this->respondCreated(['success' => true, 'message' => 'Berhasil']);
    }
    
    public function delete($id = null) {
        $userId = $this->request->user_id;
        
        $this->model->delete($id);
        return $this->respondDeleted(['success' => true]);
    }
}