<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\UserModel;

class UserController extends ApiController
{
    // GET: Ambil Profil User
    public function profile()
    {
        $userId = $this->request->user_id;
        $userModel = new UserModel();
        
        $user = $userModel->find($userId);

        if (!$user) {
            return $this->error("User tidak ditemukan", 404);
        }

        // Hapus password dari response
        unset($user['password']);

        return $this->success($user);
    }

    // PUT: Update Profil (Nama & Email)
    public function updateProfile()
    {
        $userId = $this->request->user_id;
        $userModel = new UserModel();

        // Validasi input
        // 'is_unique[users.email,id,{user_id}]' artinya: email harus unik, KECUALI untuk ID user ini sendiri.
        $rules = [
            'name' => 'required',
            'email' => "required|valid_email|is_unique[users.email,id,$userId]" 
        ];

        if (!$this->validate($rules)) {
            return $this->error($this->validator->getErrors());
        }

        $data = [
            'name' => $this->request->getVar('name'),
            'email' => $this->request->getVar('email'),
        ];

        try {
            $userModel->update($userId, $data);
            
            // Ambil data terbaru untuk dikembalikan ke frontend
            $updatedUser = $userModel->find($userId);
            unset($updatedUser['password']);

            return $this->success($updatedUser, "Profil berhasil diperbarui");
        } catch (\Exception $e) {
            return $this->error("Gagal update profile: " . $e->getMessage());
        }
    }

    // PUT: Ganti Password
    public function changePassword()
    {
        $userId = $this->request->user_id;
        $userModel = new UserModel();

        $rules = [
            'old_password' => 'required',
            'new_password' => 'required|min_length[6]',
            'confirm_password' => 'required|matches[new_password]'
        ];

        if (!$this->validate($rules)) {
            return $this->error($this->validator->getErrors());
        }

        $oldPass = $this->request->getVar('old_password');
        $newPass = $this->request->getVar('new_password');

        // 1. Cek Password Lama
        $user = $userModel->find($userId);
        if (!$user || !password_verify($oldPass, $user['password'])) {
            return $this->error("Password lama salah", 400);
        }

        // 2. Update Password Baru
        try {
            $hashedPassword = password_hash($newPass, PASSWORD_BCRYPT);
            $userModel->update($userId, ['password' => $hashedPassword]);

            return $this->success(null, "Password berhasil diubah");
        } catch (\Exception $e) {
            return $this->error("Gagal ubah password: " . $e->getMessage());
        }
    }
}
