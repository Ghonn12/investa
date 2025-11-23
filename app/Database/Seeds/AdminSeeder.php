<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run()
    {
        $data = [
            'name'     => 'Super Admin',
            'email'    => 'admin@investa.com',
            'password' => password_hash('admin123', PASSWORD_BCRYPT),
            'balance'  => 0,
            'role'     => 'ADMIN',
            'status'   => 'ACTIVE',
            'created_at' => date('Y-m-d H:i:s'),
            'updated_at' => date('Y-m-d H:i:s'),
        ];

        // Gunakan query builder untuk insert
        $this->db->table('users')->insert($data);
    }
}