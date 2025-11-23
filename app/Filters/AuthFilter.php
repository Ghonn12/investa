<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

class AuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        // Ambil header Authorization
        $header = $request->getServer('HTTP_AUTHORIZATION');
        
        if (!$header) {
            return service('response')
                ->setJSON(['message' => 'Token Required'])
                ->setStatusCode(ResponseInterface::HTTP_UNAUTHORIZED);
        }

        // Format header biasanya: "Bearer <token>"
        $token = explode(' ', $header)[1] ?? null;

        if (!$token) {
            return service('response')
                ->setJSON(['message' => 'Token Format Invalid'])
                ->setStatusCode(ResponseInterface::HTTP_UNAUTHORIZED);
        }

        try {
            // Decode Token
            // Key ini HARUS SAMA dengan yang ada di AuthController
            $key = getenv('JWT_SECRET') ?: 'rahasia_super_aman_investa_123';
            $decoded = JWT::decode($token, new Key($key, 'HS256'));

            // Simpan user_id ke request agar bisa dipakai di Controller
            $request->user_id = $decoded->uid;

        } catch (\Exception $e) {
            return service('response')
                ->setJSON(['message' => 'Token Invalid: ' . $e->getMessage()])
                ->setStatusCode(ResponseInterface::HTTP_UNAUTHORIZED);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Do nothing
    }
}
