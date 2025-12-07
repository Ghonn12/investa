<?php namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\API\ResponseTrait;
use App\Models\WalletModel;
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;
use \Exception;

class WalletController extends ResourceController
{
    use ResponseTrait;
    protected $modelName = 'App\Models\WalletModel';
    protected $format    = 'json';

    // GET all Wallets
    public function index()
    {
        $userId = $this->request->user_id;
        // Ambil wallet milik user ini
        $data = $this->model->where('user_id', $userId)->findAll();
        
        return $this->respond([
            'success' => true,
            'message' => 'Data Wallet berhasil diambil',
            'data' => $data
        ], 200); 
    }

    // CREATE Wallet (POST)
    public function create()
    {
        $userId = $this->request->user_id;
        
        // PENTING: Gunakan getPost() untuk POST form-data
        $data = $this->request->getPost(); 

        $data['user_id'] = $userId;

        // Validasi input
        $validation = \Config\Services::validation();
        $rules = [
            'nama_wallet' => 'required',
            'tipe_wallet' => 'required', // Contoh: Bank, Cash, E-Wallet
        ];

        if (!$validation->setRules($rules)->run($data)) {
             return $this->respond([
                'success' => false,
                'message' => 'Validasi gagal',
                'errors' => $validation->getErrors()
            ], 400); 
        }

        $insertedId = $this->model->insert($data);

        if ($insertedId === false) {
            return $this->respond([
                'success' => false,
                'message' => 'Gagal menambahkan data Wallet',
                'errors' => $this->model->errors()
            ], 500); 
        }

        $newData = $this->model->find($insertedId);
        return $this->respondCreated([
            'success' => true,
            'message' => 'Wallet berhasil dibuat',
            'data' => $newData
        ]); 
    }

    // UPDATE Wallet (PUT)
    public function update($id = null)
    {
        $userId = $this->request->user_id;
        
        // PENTING: Gunakan getRawInput() untuk method PUT
        $data = $this->request->getRawInput(); 

        // Cek kepemilikan data
        $wallet = $this->model->where('id', $id)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->failNotFound('Data Wallet tidak ditemukan'); 
        }

        if ($this->model->update($id, $data) === false) {
             return $this->respond([
                'success' => false,
                'message' => 'Gagal mengubah data Wallet',
                'errors' => $this->model->errors()
            ], 500);
        }

        $updatedData = $this->model->find($id);
        return $this->respond([
            'success' => true,
            'message' => 'Data Wallet berhasil diubah',
            'data' => $updatedData
        ], 200); 
    }

    // DELETE Wallet
    public function delete($id = null)
    {
        $userId = $this->request->user_id;

        // Cek kepemilikan data
        $wallet = $this->model->where('id', $id)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->failNotFound('Data Wallet tidak ditemukan'); 
        }

        if ($this->model->delete($id) === false) {
             return $this->respond([
                'success' => false,
                'message' => 'Gagal menghapus data Wallet',
                'errors' => $this->model->errors()
            ], 500);
        }

        return $this->respondDeleted([
            'success' => true,
            'message' => 'Data Wallet berhasil dihapus'
        ]); 
    }
}