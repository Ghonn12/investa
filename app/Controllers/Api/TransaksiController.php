<?php namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\API\ResponseTrait;
use App\Models\TransaksiModel;
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;

class TransaksiController extends ResourceController
{
    use ResponseTrait;
    protected $modelName = 'App\Models\TransaksiModel';
    protected $format    = 'json';

    private function getLoggedInUserId() {
        $key = getenv('JWT_SECRET');
        $header = $this->request->getHeaderLine('Authorization');
        if (!empty($header) && preg_match('/Bearer\s(\S+)/', $header, $matches)) {
            try {
                $decoded = JWT::decode($matches[1], new Key($key, 'HS256'));
                return $decoded->uid;
            } catch (\Exception $e) { return null; }
        }
        return null;
    }

    public function index() {
        $userId = $this->getLoggedInUserId();
        if(!$userId) return $this->failUnauthorized();

        $data = $this->model
            ->select('transactions.*, categories.nama_kategori, wallets.nama_wallet')
            ->join('categories', 'categories.id = transactions.category_id', 'left')
            ->join('wallets', 'wallets.id = transactions.wallet_id', 'left')
            ->where('transactions.user_id', $userId)
            ->orderBy('transactions.date', 'DESC')
            ->findAll();
        
        return $this->respond(['success' => true, 'data' => $data]);
    }

    public function create() {
        $userId = $this->getLoggedInUserId();
        if(!$userId) return $this->failUnauthorized();

        $data = $this->request->getPost();
        $data['user_id'] = $userId;
        // Isi title punya temanmu dgn deskripsi kita
        $data['title'] = $data['deskripsi'] ?? 'Transaksi Baru'; 

        $this->model->insert($data);
        return $this->respondCreated(['success' => true, 'message' => 'Berhasil']);
    }
    
    public function delete($id = null) {
        $userId = $this->getLoggedInUserId();
        if(!$userId) return $this->failUnauthorized();
        
        $this->model->delete($id);
        return $this->respondDeleted(['success' => true]);
    }
}