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

            if (isset($body['quoteResponse']['result'][0])) {
                $result = $body['quoteResponse']['result'][0];

                return [
                    'price' => (float) ($result['regularMarketPrice'] ?? 0),
                    'changePercent' => (float) ($result['regularMarketChangePercent'] ?? 0)
                ];
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
        $basePrice = 1000;
        switch ($symbol) {
            case 'BBCA.JK':
                $basePrice = 9200;
                break;
            case 'TLKM.JK':
                $basePrice = 3800;
                break;
            case 'BBRI.JK':
                $basePrice = 5400;
                break;
            case 'BTC-USD':
                $basePrice = 95000;
                break;
            case 'ETH-USD':
                $basePrice = 3500;
                break;
            default:
                $basePrice = 1000;
                break;
        }

        $price = $basePrice + rand(-50, 50);
        $changePercent = rand(-300, 300) / 100.0; // -3.00% s/d +3.00%

        return [
            'price' => $price,
            'changePercent' => $changePercent
        ];
    }
}