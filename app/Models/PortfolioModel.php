<?php

namespace App\Models;

use CodeIgniter\Model;

class PortfolioModel extends Model
{
    protected $table            = 'portfolios';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    
    // PERBAIKAN PENTING: Pastikan ada 'symbol' di sini
    protected $allowedFields    = ['user_id', 'symbol', 'quantity', 'average_price'];
    
    protected $useTimestamps    = true;
}