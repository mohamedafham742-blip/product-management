<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin User',
                'password' => Hash::make('password123'),
                'email_verified_at' => now(),
            ]
        );

        $sampleProducts = [
            [
                'name' => 'Ceramic Minimalist Vase',
                'sku' => 'VASE-CRM-001',
                'description' => 'Handcrafted minimalist ceramic vase in matte sandstone finish.',
                'price' => 45.00,
                'quantity' => 28,
                'status' => 'active',
            ],
            [
                'name' => 'Organic Linen Throw Pillow',
                'sku' => 'PLW-LNN-002',
                'description' => '100% organic textured linen pillow with feather insert.',
                'price' => 32.50,
                'quantity' => 15,
                'status' => 'active',
            ],
            [
                'name' => 'Sculptural Wooden Bowl',
                'sku' => 'BWL-OAK-003',
                'description' => 'Solid white oak decorative bowl carved from reclaimed timber.',
                'price' => 78.00,
                'quantity' => 8,
                'status' => 'active',
            ],
            [
                'name' => 'Matte Stoneware Coffee Mug Set',
                'sku' => 'MUG-STN-004',
                'description' => 'Set of 4 artisanal stoneware mugs with ergonomic handles.',
                'price' => 38.00,
                'quantity' => 0,
                'status' => 'inactive',
            ],
            [
                'name' => 'Brushed Brass Table Lamp',
                'sku' => 'LMP-BRS-005',
                'description' => 'Architectural desk lamp with warm dimmable ambient LED glow.',
                'price' => 120.00,
                'quantity' => 12,
                'status' => 'active',
            ],
        ];

        foreach ($sampleProducts as $p) {
            Product::updateOrCreate(['sku' => $p['sku']], $p);
        }
    }
}
