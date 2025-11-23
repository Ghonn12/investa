<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\TransactionModel;

class TransactionAdminController extends ApiController
{
    public function index()
    {
        $db = \Config\Database::connect();

        // Query untuk mengambil SEMUA transaksi dan menggabungkannya dengan nama user
        $transactions = $db->table('transactions')
                            ->select('transactions.*, users.name as user_name, users.email as user_email')
                            ->join('users', 'users.id = transactions.user_id')
                            ->orderBy('transactions.date', 'DESC')
                            ->get()
                            ->getResultArray();
                            
        return $this->success($transactions);
    }
}