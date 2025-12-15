<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;

class AiController extends ApiController
{
    // Endpoint Utama Chat
    public function chat()
    {
        // 1. AMBIL INPUT AMAN (Agar tidak Crash 500 jika JSON rusak)
        try {
            // Coba ambil JSON, jika gagal fallback ke Form Data
            $json = $this->request->getJSON(true);
            $input = $json ? $json : $this->request->getVar();
        } catch (\Exception $e) {
            return $this->error("Invalid JSON Format", 400);
        }

        // Validasi Manual
        $userMessage = $input['message'] ?? null;
        if (empty($userMessage)) {
            return $this->error("Field 'message' is required", 400);
        }
        
        // 2. API KEY SETUP
        $apiKey = getenv('GEMINI_API_KEY');
        if (!$apiKey) return $this->error('Server config error: API Key missing', 500);

        // 3. SETUP MODEL (Gunakan Model yang Valid)
        // Opsi: 'gemini-1.5-flash' (Stabil & Cepat) atau 'gemini-1.5-pro' (Lebih pinter tapi mahal)
        // 'gemini-2.5-flash' BELUM ADA.
        $modelName = 'gemini-1.5-flash'; 
        
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$modelName}:generateContent?key=" . rawurlencode($apiKey);
        
        $systemInstruction = "Kamu adalah 'Investa Assistant', asisten keuangan cerdas. Jawablah pertanyaan seputar saham, crypto, dan tips keuangan dengan ramah, singkat, dan gunakan format Markdown yang rapi dalam Bahasa Indonesia.";

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
            // System Instruction (Hanya jalan di model 1.5 ke atas)
            "system_instruction" => [
                "parts" => [
                    ["text" => $systemInstruction]
                ]
            ]
        ];

        // 4. KIRIM REQUEST
        try {
            $client = \Config\Services::curlrequest();
            $response = $client->post($url, [
                'headers' => ['Content-Type' => 'application/json'],
                'json' => $body,
                'http_errors' => false, // Biar kita bisa handle error code manual
                'timeout' => 30 // Mencegah loading selamanya
            ]);

            $result = json_decode($response->getBody(), true);
            
            // Cek Error dari Google
            if ($response->getStatusCode() !== 200) {
                // Ambil pesan error spesifik dari Google
                $googleError = $result['error']['message'] ?? 'Unknown AI Error';
                return $this->error("AI Error ({$response->getStatusCode()}): $googleError", $response->getStatusCode());
            }

            // Ambil Balasan
            $reply = $result['candidates'][0]['content']['parts'][0]['text'] ?? 'Maaf, saya tidak dapat memproses jawaban saat ini.';
            
            return $this->success(['reply' => $reply]);

        } catch (\Exception $e) {
            return $this->error("Connection Error: " . $e->getMessage(), 500);
        }
    }

    // ENDPOINT DEBUG (Cek Model apa saja yang tersedia bagi API Key Anda)
    public function testConnection()
    {
        $apiKey = getenv('GEMINI_API_KEY');
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