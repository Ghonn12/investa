<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table            = 'users';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    
    // PERBAIKAN: Tambahkan 'balance' agar saldo bisa diupdate
    protected $allowedFields    = ['email', 'password', 'name', 'balance', 'role', 'status'];
    
    protected $useTimestamps    = true;
}