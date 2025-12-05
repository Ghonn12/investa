<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddFeaturesToInvesta extends Migration
{
    public function up()
    {
        // 1. BUAT TABEL WALLETS (Dompet)
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'nama_wallet' => [ // Sesuai kodingan backend/flutter kita
                'type'       => 'VARCHAR',
                'constraint' => 100,
            ],
            'tipe_wallet' => [
                'type'       => 'VARCHAR',
                'constraint' => 50,
            ],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('wallets', true);

        // 2. BUAT TABEL CATEGORIES (Kategori)
        $this->forge->addField([
            'id' => [
                'type'           => 'INT',
                'constraint'     => 11,
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'user_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
            ],
            'nama_kategori' => [ // Sesuai kodingan backend/flutter kita
                'type'       => 'VARCHAR',
                'constraint' => 100,
            ],
            'tipe' => [
                'type'       => 'ENUM',
                'constraint' => ['Pemasukan', 'Pengeluaran', 'INCOME', 'EXPENSE'], // Support dua bahasa biar aman
            ],
            'created_at' => ['type' => 'DATETIME', 'null' => true],
            'updated_at' => ['type' => 'DATETIME', 'null' => true],
        ]);
        $this->forge->addKey('id', true);
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->createTable('categories', true);

        // 3. MODIFIKASI TABEL TRANSACTIONS (Punya Temanmu)
        // Kita tambahkan wallet_id, category_id, dan sesuaikan ENUM
        
        // A. Ubah tipe kolom 'type' agar menerima 'Pemasukan'/'Pengeluaran' juga
        // Note: modifyColumn agak tricky di CI4, kita pakai query manual untuk safety
        $this->db->query("ALTER TABLE transactions MODIFY COLUMN type ENUM('INCOME', 'EXPENSE', 'Pemasukan', 'Pengeluaran')");

        // B. Tambah Kolom Baru
        $fields = [
            'wallet_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
                'null'       => true, // Null dulu biar data lama ga error
                'after'      => 'user_id'
            ],
            'category_id' => [
                'type'       => 'INT',
                'constraint' => 11,
                'unsigned'   => true,
                'null'       => true,
                'after'      => 'wallet_id'
            ],
            'deskripsi' => [ // Kita tambah ini karena Flutter kita kirim 'deskripsi', temanmu pakai 'title'
                'type'       => 'TEXT',
                'null'       => true,
                'after'      => 'title'
            ]
        ];
        $this->forge->addColumn('transactions', $fields);

        // C. Tambah Foreign Key
        // Karena addColumn FK di CI4 kadang bug jika tabel sudah ada, kita pakai SQL manual
        $this->db->query("ALTER TABLE transactions ADD CONSTRAINT fk_trx_wallet FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE SET NULL ON UPDATE CASCADE");
        $this->db->query("ALTER TABLE transactions ADD CONSTRAINT fk_trx_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE");
    }

    public function down()
    {
        // Hapus kolom tambahan di transactions
        $this->forge->dropForeignKey('transactions', 'fk_trx_wallet');
        $this->forge->dropForeignKey('transactions', 'fk_trx_category');
        $this->forge->dropColumn('transactions', ['wallet_id', 'category_id', 'deskripsi']);

        // Hapus tabel
        $this->forge->dropTable('categories');
        $this->forge->dropTable('wallets');
    }
}