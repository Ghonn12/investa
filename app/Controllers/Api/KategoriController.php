<?php namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\API\ResponseTrait;
use App\Models\KategoriModel;
use \Firebase\JWT\JWT;
use \Firebase\JWT\Key;
use \Exception;

class KategoriController extends ResourceController
{
    use ResponseTrait;
    protected $modelName = 'App\Models\KategoriModel';
    protected $format    = 'json';

    // GET all Categories
    public function index()
    {
        $userId = $this->request->user_id;
        $data = $this->model->where('user_id', $userId)->findAll();
        
        return $this->respond([
            'success' => true,
            'message' => 'Data Kategori berhasil diambil',
            'data' => $data
        ], 200); 
    }

    // CREATE Kategori (POST)
    public function create()
    {
        $userId = $this->request->user_id;
        
        // PENTING: Gunakan getPost() untuk POST form-data
        $data = $this->request->getPost(); 

        $data['user_id'] = $userId;

        // Validasi
        $validation = \Config\Services::validation();
        $rules = [
            'nama_kategori' => 'required',
            // Support Bahasa Indo (Pemasukan/Pengeluaran) dan Inggris (INCOME/EXPENSE)
            'tipe' => 'required|in_list[Pemasukan,Pengeluaran,INCOME,EXPENSE]',
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
                'message' => 'Gagal menambahkan data Kategori',
                'errors' => $this->model->errors()
            ], 500); 
        }

        $newData = $this->model->find($insertedId);
        return $this->respondCreated([
            'success' => true,
            'message' => 'Kategori berhasil ditambahkan',
            'data' => $newData
        ]); 
    }

    // UPDATE Kategori (PUT)
    public function update($id = null)
    {
        $userId = $this->request->user_id;
        
        // PENTING: Gunakan getRawInput() untuk method PUT
        $data = $this->request->getRawInput(); 

        // Cek kepemilikan
        $kategori = $this->model->where('id', $id)->where('user_id', $userId)->first();
        if (!$kategori) {
            return $this->failNotFound('Data Kategori tidak ditemukan'); 
        }

        if ($this->model->update($id, $data) === false) {
             return $this->respond([
                'success' => false,
                'message' => 'Gagal mengubah data Kategori',
                'errors' => $this->model->errors()
            ], 500);
        }

        $updatedData = $this->model->find($id);
        return $this->respond([
            'success' => true,
            'message' => 'Data Kategori berhasil diubah',
            'data' => $updatedData
        ], 200); 
    }

    // DELETE Kategori
    public function delete($id = null)
    {
        $userId = $this->request->user_id;

        // Cek kepemilikan
        $kategori = $this->model->where('id', $id)->where('user_id', $userId)->first();
        if (!$kategori) {
            return $this->failNotFound('Data Kategori tidak ditemukan'); 
        }

        if ($this->model->delete($id) === false) {
             return $this->respond([
                'success' => false,
                'message' => 'Gagal menghapus data Kategori',
                'errors' => $this->model->errors()
            ], 500);
        }

        return $this->respondDeleted([
            'success' => true,
            'message' => 'Data Kategori berhasil dihapus'
        ]); 
    }
}