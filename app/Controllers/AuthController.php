<?php

namespace App\Controllers;

use App\Controllers\ApiController; 
use App\Models\UserModel;
use Firebase\JWT\JWT;

class AuthController extends ApiController
{
    public function register()
    {
        $rules = [
            'email' => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[6]',
            'name' => 'required'
        ];

        if (!$this->validate($rules)) {
            return $this->error($this->validator->getErrors());
        }

        $model = new UserModel();
        $data = [
            'email'    => $this->request->getVar('email'),
            'password' => password_hash($this->request->getVar('password'), PASSWORD_BCRYPT),
            'name'     => $this->request->getVar('name'),
        ];

        $model->insert($data);

        return $this->success(null, 'User registered successfully', 201);
    }

    public function login()
    {
        $rules = [
            'email' => 'required|valid_email',
            'password' => 'required'
        ];

        if (!$this->validate($rules)) {
            return $this->error($this->validator->getErrors());
        }

        $model = new UserModel();
        $user = $model->where('email', $this->request->getVar('email'))->first();

        if (!$user || !password_verify($this->request->getVar('password'), $user['password'])) {
            return $this->error('Invalid email or password', 401);
        }

        if ($user['status'] === 'BLOCKED') {
            log_message('warning', 'Login blocked: User status is BLOCKED for email ' . $user['email']);
            return $this->error('Akun Anda telah dibekukan. Silakan hubungi Admin.', 403); // 403 Forbidden
        }

        // Generate JWT
        $key = getenv('JWT_SECRET') ?: 'rahasia_super_aman_investa_123';
        $payload = [
            'iss' => 'investa-server',
            'aud' => 'investa-app',
            'iat' => time(),
            'exp' => time() + (60 * 60 * 24 * 30), // Expire 30 hari
            'uid' => $user['id'], // User ID disimpan di token
        ];

        $token = JWT::encode($payload, $key, 'HS256');

        return $this->success([
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role']
            ]
        ], 'Login successful');
    }
}