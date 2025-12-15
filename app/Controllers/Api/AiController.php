<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;

class AiController extends ApiController
{
    // Endpoint Utama Chat
    public function chat()
    {
        // --- 1. LOGGING AWAL ---
        log_message('info', '[Gemini] Request masuk ke endpoint chat.');

        try {
            $json = $this->request->getJSON(true);
            $input = $json ? $json : $this->request->getVar();
        } catch (\Exception $e) {
            log_message('error', '[Gemini] JSON Error: ' . $e->getMessage());
            return $this->error("Invalid JSON Format", 400);
        }

        $userMessage = $input['message'] ?? null;
        if (empty($userMessage)) {
            return $this->error("Field 'message' is required", 400);
        }

        // --- 2. CEK API KEY YANG TERBACA ---
        $apiKey = getenv('GEMINI_API_KEY');
        
        if (!$apiKey) {
            log_message('critical', '[Gemini] API Key KOSONG/Tidak terbaca dari .env');
            return $this->error('Server config error: API Key missing', 500);
        }

        // DEBUG: Log 6 karakter pertama Key untuk memastikan ini Key BARU atau LAMA
        // Jangan log full key demi keamanan, cukup depannya saja.
        $maskedKey = substr($apiKey, 0, 6) . '...' . substr($apiKey, -4);
        log_message('info', '[Gemini] Menggunakan API Key: ' . $maskedKey);

        // --- 3. SETUP REQUEST ---
        $modelName = 'gemini-1.5-flash';
        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$modelName}:generateContent?key=" . rawurlencode($apiKey);

        $systemInstruction = "Kamu adalah 'Investa Assistant'. Jawab singkat, format markdown, Bahasa Indonesia.";

        $body = [
            "contents" => [
                [
                    "role" => "user",
                    "parts" => [["text" => $userMessage]]
                ]
            ],
            "system_instruction" => [
                "parts" => [["text" => $systemInstruction]]
            ]
        ];

        // --- 4. EKSEKUSI & LOGGING HASIL ---
        try {
            $client = \Config\Services::curlrequest();
            
            log_message('info', '[Gemini] Mengirim request ke Google...');

            $response = $client->post($url, [
                'headers' => ['Content-Type' => 'application/json'],
                'json' => $body,
                'http_errors' => false,
                'timeout' => 30,
                'verify' => false 
            ]);

            $rawBody = $response->getBody();
            $statusCode = $response->getStatusCode();

            // Decode
            $result = json_decode($rawBody, true);

            // --- 5. ANALISA ERROR DETIL ---
            if ($statusCode !== 200) {
                // Log FULL Response dari Google supaya ketahuan salahnya dimana
                log_message('error', '[Gemini] ERROR GOOGLE (' . $statusCode . '): ' . $rawBody);

                // Kembalikan error detail ke user (sementara untuk debugging)
                $errorMessage = $result['error']['message'] ?? 'Unknown AI Error';
                $errorStatus = $result['error']['status'] ?? 'UNKNOWN_STATUS';
                
                return $this->error("AI Error ($statusCode) [$errorStatus]: $errorMessage", $statusCode);
            }

            log_message('info', '[Gemini] Sukses menerima balasan.');

            $reply = $result['candidates'][0]['content']['parts'][0]['text'] ?? 'No text response.';
            return $this->success(['reply' => $reply]);

        } catch (\Exception $e) {
            log_message('critical', '[Gemini] Connection Exception: ' . $e->getMessage());
            return $this->error("Connection Error: " . $e->getMessage(), 500);
        }
    }

    // ENDPOINT DEBUG (Cek Model apa saja yang tersedia bagi API Key Anda)
    public function testConnection()
    {
        $apiKey = getenv('GEMINI_API_KEY');
        if (!$apiKey)
            return $this->error('API Key missing', 500);

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