<?php namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddFinanceFeatures extends Migration
{
    public function up()
    {
        // 1. Tabel Wallets
        $this->forge->addField([
            'id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true],
            'nama_wallet' => ['type' => 'VARCHAR', 'constraint' => 100],
            'tipe_wallet' => ['type' => 'VARCHAR', 'constraint' => 50],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('wallets', true);

        // 2. Tabel Categories
        $this->forge->addField([
            'id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'auto_increment' => true],
            'user_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true],
            'nama_kategori' => ['type' => 'VARCHAR', 'constraint' => 100],
            'tipe' => ['type' => 'ENUM', 'constraint' => ['Pemasukan', 'Pengeluaran', 'INCOME', 'EXPENSE']],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('categories', true);

        // 3. Update Tabel Transactions (Punya Temanmu)
        // Tambah kolom wallet_id, category_id, deskripsi
        $fields = [
            'wallet_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'null' => true, 'after' => 'user_id'],
            'category_id' => ['type' => 'INT', 'constraint' => 11, 'unsigned' => true, 'null' => true, 'after' => 'wallet_id'],
            'deskripsi' => ['type' => 'TEXT', 'null' => true, 'after' => 'title']
        ];
        $this->forge->addColumn('transactions', $fields);
        
        $this->db->query("ALTER TABLE transactions MODIFY COLUMN type ENUM('INCOME', 'EXPENSE', 'Pemasukan', 'Pengeluaran')");
    }

    public function down()
    {
        $this->forge->dropColumn('transactions', ['wallet_id', 'category_id', 'deskripsi']);
        $this->forge->dropTable('categories');
        $this->forge->dropTable('wallets');
    }
}