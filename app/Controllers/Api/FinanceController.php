<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\TransactionModel;
use App\Models\UserModel;

class FinanceController extends ApiController
{
    // GET: Ambil Riwayat Transaksi
    public function index()
    {
        $model = new TransactionModel();
        $data = $model->where('user_id', $this->request->user_id)
                      ->orderBy('date', 'DESC')
                      ->findAll();
        return $this->success($data);
    }

    // POST: Catat Pemasukan/Pengeluaran
    public function create()
    {
        // Validasi
        $rules = [
            'title' => 'required',
            'amount' => 'required|numeric',
            'type' => 'required|in_list[INCOME,EXPENSE]',
            'date' => 'required|valid_date',
            'category' => 'required'
        ];

        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $db = \Config\Database::connect();
        $db->transStart(); // Mulai Transaksi Database

        try {
            $userId = $this->request->user_id;
            $amount = (float)$this->request->getVar('amount');
            $type = $this->request->getVar('type');

            // 1. Simpan Log Transaksi
            $trxModel = new TransactionModel();
            $trxModel->insert([
                'user_id' => $userId,
                'title' => $this->request->getVar('title'),
                'amount' => $amount,
                'type' => $type,
                'category' => $this->request->getVar('category'),
                'date' => $this->request->getVar('date'),
            ]);

            // 2. Update Saldo User (Otomatis)
            $userModel = new UserModel();
            $user = $userModel->find($userId);
            $currentBalance = (float)$user['balance'];

            if ($type == 'INCOME') {
                $newBalance = $currentBalance + $amount;
            } else {
                $newBalance = $currentBalance - $amount;
            }

            $userModel->update($userId, ['balance' => $newBalance]);

            $db->transComplete();

            return $this->success(['new_balance' => $newBalance], 'Transaksi berhasil dicatat');

        } catch (\Exception $e) {
            $db->transRollback();
            return $this->error('Gagal menyimpan: ' . $e->getMessage(), 500);
        }
    }
}