<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class InvestaFullSchema extends Migration
{
    public function up()
    {
        // 1. Tabel Users (Ditambah kolom balance)
        $this->forge->addField([
            'id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'name' => ['type' => 'VARCHAR', 'constraint' => 100],
            'email' => ['type' => 'VARCHAR', 'constraint' => 100, 'unique' => true],
            'password' => ['type' => 'VARCHAR', 'constraint' => 255],
            'balance' => ['type' => 'DECIMAL', 'constraint' => '20,2', 'default' => 0.00], // Saldo Rupiah
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->createTable('users', true);

        // 2. Tabel Transactions (Manajemen Uang: Pemasukan/Pengeluaran)
        $this->forge->addField([
            'id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true],
            'title' => ['type' => 'VARCHAR', 'constraint' => 255],
            'amount' => ['type' => 'DECIMAL', 'constraint' => '20,2'],
            'type' => ['type' => 'ENUM', 'constraint' => ['INCOME', 'EXPENSE']],
            'category' => ['type' => 'VARCHAR', 'constraint' => 100], // Makan, Transport, Gaji
            'date' => ['type' => 'DATE'],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('transactions', true);

        // 3. Tabel Portfolios (Simpan Saham/Crypto yang dimiliki)
        $this->forge->addField([
            'id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true],
            'symbol' => ['type' => 'VARCHAR', 'constraint' => 20], // BBCA.JK, BTC-USD
            'quantity' => ['type' => 'DECIMAL', 'constraint' => '20,6'], // Bisa desimal untuk crypto
            'average_price' => ['type' => 'DECIMAL', 'constraint' => '20,2'], // Harga beli rata-rata
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('portfolios', true);
    }

    public function down()
    {
        $this->forge->dropTable('portfolios');
        $this->forge->dropTable('transactions');
        $this->forge->dropTable('users');
    }
}
