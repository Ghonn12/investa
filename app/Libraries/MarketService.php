<?php

namespace App\Libraries;

class MarketService
{
    private $apiKey;
    private $apiHost;

    public function __construct()
    {
        $this->apiKey = getenv('RAPIDAPI_KEY');
        $this->apiHost = getenv('RAPIDAPI_HOST');
    }

    public function getPrice($symbol)
    {
        // 1. Coba ambil dari Real API
        try {
            // Jika API Key belum diisi, langsung lempar ke catch (pakai Mock)
            if (empty($this->apiKey) || $this->apiKey === 'isi_key_rapidapi_anda_disini') {
                throw new \Exception("API Key belum diset");
            }

            $url = "https://{$this->apiHost}/market/v2/get-quotes?region=US&symbols={$symbol}";
            $client = \Config\Services::curlrequest();

            $response = $client->get($url, [
                'headers' => [
                    'x-rapidapi-key' => $this->apiKey,
                    'x-rapidapi-host' => $this->apiHost
                ],
                'http_errors' => false,
                'verify' => false, // PENTING: Abaikan SSL Check di Localhost (XAMPP)
                'timeout' => 5     // Timeout cepat agar tidak loading lama
            ]);

            $body = json_decode($response->getBody(), true);

            if (isset($body['quoteResponse']['result'][0]['regularMarketPrice'])) {
                return (float)$body['quoteResponse']['result'][0]['regularMarketPrice'];
            }

        } catch (\Exception $e) {
            // Lanjut ke fallback di bawah
            // log_message('error', 'API Error: ' . $e->getMessage());
        }

        // 2. FALLBACK: MOCK DATA (Data Palsu untuk Testing)
        // Agar Anda tetap bisa tes logika Beli/Jual meskipun API Error/Limit Habis
        return $this->generateMockPrice($symbol);
    }

    private function generateMockPrice($symbol)
    {
        // Harga pura-pura berdasarkan simbol agar konsisten
        switch ($symbol) {
            case 'BBCA.JK': return 9200 + rand(-50, 50); // Sekitar 9200
            case 'TLKM.JK': return 3800 + rand(-20, 20); // Sekitar 3800
            case 'BBRI.JK': return 5400 + rand(-30, 30); // Sekitar 5400
            case 'BTC-USD': return 95000 + rand(-100, 100); // Crypto
            case 'ETH-USD': return 3500 + rand(-50, 50);
            default: return 1000 + rand(0, 100); // Saham antah berantah
        }
    }
}