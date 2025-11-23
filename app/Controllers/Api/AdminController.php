<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\UserModel;
use App\Models\TransactionModel;

class AdminController extends ApiController
{
    // 1. Dashboard Statistik
    public function dashboard()
    {
        $userModel = new UserModel();
        $trxModel = new TransactionModel();

        // Hitung total user (kecuali admin)
        $totalUsers = $userModel->where('role', 'USER')->countAllResults();
        
        // Hitung total transaksi
        $totalTrx = $trxModel->countAll();
        
        // Hitung total uang beredar (balance user)
        $db = \Config\Database::connect();
        $query = $db->query("SELECT SUM(balance) as total FROM users WHERE role = 'USER'");
        $totalBalance = $query->getRow()->total ?? 0;

        return $this->success([
            'total_users' => $totalUsers,
            'total_transactions' => $totalTrx,
            'total_balance' => (float)$totalBalance
        ]);
    }

    // 2. List Users
    public function users()
    {
        $userModel = new UserModel();
        // Ambil semua user biasa, urutkan dari terbaru
        $data = $userModel->where('role', 'USER')
                          ->orderBy('created_at', 'DESC')
                          ->findAll();
        return $this->success($data);
    }

    // 3. Create User Manual (Optional)
    public function createUser()
    {
        $rules = [
            'email' => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[6]',
            'name' => 'required'
        ];

        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $model = new UserModel();
        $data = [
            'name' => $this->request->getVar('name'),
            'email' => $this->request->getVar('email'),
            'password' => password_hash($this->request->getVar('password'), PASSWORD_BCRYPT),
            'role' => 'USER',
            'status' => 'ACTIVE',
            'balance' => 0
        ];

        $model->insert($data);
        return $this->success(null, 'User created successfully');
    }

    // 4. Update User (Block/Unblock)
    public function updateUser($id = null)
    {
        $model = new UserModel();
        $data = $this->request->getJSON(true); // Ambil JSON Body

        $updateData = [];
        if (isset($data['name'])) $updateData['name'] = $data['name'];
        if (isset($data['status'])) $updateData['status'] = $data['status']; // ACTIVE / BLOCKED
        
        if (empty($updateData)) return $this->error('No data to update');

        $model->update($id, $updateData);
        return $this->success(null, 'User updated successfully');
    }

    // 5. Delete User
    public function deleteUser($id = null)
    {
        $model = new UserModel();
        $model->delete($id);
        return $this->success(null, 'User deleted successfully');
    }
    public function getUserGrowth()
    {
        $db = \Config\Database::connect();
        $startDate = date('Y-m-d', strtotime('-6 months'));

        // Query untuk menghitung jumlah user yang terdaftar per bulan
        // Menggunakan DATE_FORMAT untuk mengelompokkan berdasarkan tahun-bulan
        // Query ini akan mengembalikan jumlah pendaftaran user, bukan total kumulatif
        $query = $db->query("
            SELECT 
                DATE_FORMAT(created_at, '%Y-%m') AS period, 
                COUNT(id) AS new_users
            FROM users
            WHERE role = 'USER' AND created_at >= '{$startDate}'
            GROUP BY period
            ORDER BY period ASC
        ");

        $rawResults = $query->getResultArray();
        
        // Memformat data untuk Flutter: mengisi bulan yang kosong dengan nol (0)
        // dan menghitung total kumulatif untuk representasi yang lebih baik di grafik
        
        $months = [];
        $currentMonth = strtotime($startDate);
        $endMonth = time();

        while ($currentMonth <= $endMonth) {
            $period = date('Y-m', $currentMonth);
            $months[$period] = 0;
            // Pindah ke bulan berikutnya
            $currentMonth = strtotime('+1 month', $currentMonth);
        }

        // Isi data yang ada dari DB
        foreach ($rawResults as $row) {
            $months[$row['period']] = (int)$row['new_users'];
        }

        // Hitung Kumulatif dan siapkan label
        $cumulative = 0;
        $formattedData = [];
        $labels = [];

        foreach ($months as $period => $newUsers) {
            $cumulative += $newUsers;
            $formattedData[] = $cumulative; // Kirim total kumulatif
            $labels[] = date('M', strtotime($period . '-01')); // Jan, Feb, Mar, etc.
        }

        return $this->success([
            'labels' => $labels,
            'growth_data' => $formattedData
        ]);
    }
}