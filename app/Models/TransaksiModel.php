<?php namespace App\Models;
use CodeIgniter\Model;
class TransaksiModel extends Model {
    protected $table = 'transactions';
    protected $primaryKey = 'id';
    protected $allowedFields = ['user_id', 'wallet_id', 'category_id', 'title', 'deskripsi', 'amount', 'type', 'date'];
    protected $useTimestamps = true;
}