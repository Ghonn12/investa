<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddRoleAndStatusToUsers extends Migration
{
    public function up()
    {
        $this->forge->addColumn('users', [
            'role' => [
                'type'       => 'ENUM',
                'constraint' => ['USER', 'ADMIN'],
                'default'    => 'USER',
                'after'      => 'password' // Posisi kolom (opsional)
            ],
            'status' => [
                'type'       => 'ENUM',
                'constraint' => ['ACTIVE', 'BLOCKED'],
                'default'    => 'ACTIVE',
                'after'      => 'role'
            ],
        ]);
    }

    public function down()
    {
        $this->forge->dropColumn('users', 'role');
        $this->forge->dropColumn('users', 'status');
    }
}