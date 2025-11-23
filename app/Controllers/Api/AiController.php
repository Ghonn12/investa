<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;

class AiController extends ApiController
{
    // Endpoint Utama Chat
    public function chat()
    {
        // 1. Validasi Input
        $rules = ['message' => 'required'];
        if (!$this->validate($rules)) return $this->error($this->validator->getErrors());

        $userMessage = $this->request->getVar('message');
        
        // AMBIL KEY & BERSIHKAN
        $apiKey = getenv('GEMINI_API_KEY');
        $apiKey = trim($apiKey ?? ''); 

        if (!$apiKey) return $this->error('Server config error: API Key missing', 500);

        // 2. Setup Request
        // KITA GUNAKAN MODEL YANG TERSEDIA DI LIST ANDA
        $modelName = 'gemini-2.5-flash'; 
        
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$modelName}:generateContent?key=" . rawurlencode($apiKey);
        
        $systemInstruction = "Kamu adalah 'Investa Assistant', asisten keuangan cerdas. Jawablah pertanyaan seputar saham, crypto, dan tips keuangan dengan ramah dan ringkas dalam Bahasa Indonesia.";

        // Payload
        $body = [
            "contents" => [
                [
                    "role" => "user",
                    "parts" => [
                        ["text" => $userMessage]
                    ]
                ]
            ],
            "system_instruction" => [
                "parts" => [
                    ["text" => $systemInstruction]
                ]
            ]
        ];

        // 3. Kirim Request (CURL)
        try {
            $client = \Config\Services::curlrequest();
            $response = $client->post($url, [
                'headers' => ['Content-Type' => 'application/json'],
                'json' => $body,
                'http_errors' => false
            ]);

            $result = json_decode($response->getBody(), true);
            
            if ($response->getStatusCode() !== 200) {
                $errorMsg = $result['error']['message'] ?? 'Unknown Error';
                return $this->error("AI Error ({$response->getStatusCode()}): $errorMsg", $response->getStatusCode());
            }

            $reply = $result['candidates'][0]['content']['parts'][0]['text'] ?? 'Maaf, saya tidak mengerti.';
            return $this->success(['reply' => $reply]);

        } catch (\Exception $e) {
            return $this->error("Connection Error: " . $e->getMessage(), 500);
        }
    }

    // ENDPOINT DEBUG (Bisa dihapus nanti jika sudah production)
    public function testConnection()
    {
        $apiKey = getenv('GEMINI_API_KEY');
        $apiKey = trim($apiKey ?? ''); 

        if (!$apiKey) return $this->error('API Key missing', 500);

        $url = "https://generativelanguage.googleapis.com/v1beta/models?key=" . rawurlencode($apiKey);

        try {
            $client = \Config\Services::curlrequest();
            $response = $client->get($url, ['http_errors' => false]);
            $result = json_decode($response->getBody(), true);

            return $this->success($result, "Status Code: " . $response->getStatusCode());
        } catch (\Exception $e) {
            return $this->error($e->getMessage());
        }
    }
}