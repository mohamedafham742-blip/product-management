<?php

namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class ProductController extends Controller
{
    /**
     * Display a listing of the products.
     */
    public function index(Request $request): Response
    {
        $search = $request->query('search');
        $status = $request->query('status', 'all');

        $products = Product::query()
            ->when($search, function ($query, $search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', "%{$search}%")
                      ->orWhere('sku', 'like', "%{$search}%")
                      ->orWhere('description', 'like', "%{$search}%");
                });
            })
            ->when($status && $status !== 'all', function ($query) use ($status) {
                $query->where('status', $status);
            })
            ->latest('id')
            ->paginate(8)
            ->withQueryString();

        $stats = [
            'total' => Product::count(),
            'active' => Product::where('status', 'active')->count(),
            'inactive' => Product::where('status', 'inactive')->count(),
            'total_stock' => (int) Product::sum('quantity'),
        ];

        return Inertia::render('Products/Index', [
            'products' => $products,
            'filters' => [
                'search' => $search,
                'status' => $status,
            ],
            'stats' => $stats,
        ]);
    }

    /**
     * Store a newly created product in storage.
     */
    public function store(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'max:100', 'unique:products,sku'],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'integer', 'min:0'],
            'status' => ['required', 'in:active,inactive'],
        ], [
            'name.required' => 'The product name is required.',
            'sku.required' => 'The product code / SKU is required.',
            'sku.unique' => 'A product with this SKU already exists.',
            'price.required' => 'The product price is required.',
            'price.numeric' => 'The price must be a valid number.',
            'quantity.required' => 'The product stock quantity is required.',
            'quantity.integer' => 'Quantity must be a whole number.',
            'status.required' => 'Please select a product status.',
        ]);

        Product::create($validated);

        return redirect()->route('products.index')->with('success', 'Product created successfully.');
    }

    /**
     * Display the specified product.
     */
    public function show(Product $product)
    {
        return response()->json($product);
    }

    /**
     * Update the specified product in storage.
     */
    public function update(Request $request, Product $product): RedirectResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'sku' => ['required', 'string', 'max:100', Rule::unique('products', 'sku')->ignore($product->id)],
            'description' => ['nullable', 'string'],
            'price' => ['required', 'numeric', 'min:0'],
            'quantity' => ['required', 'integer', 'min:0'],
            'status' => ['required', 'in:active,inactive'],
        ], [
            'name.required' => 'The product name is required.',
            'sku.required' => 'The product code / SKU is required.',
            'sku.unique' => 'A product with this SKU already exists.',
            'price.required' => 'The product price is required.',
            'price.numeric' => 'The price must be a valid number.',
            'quantity.required' => 'The product stock quantity is required.',
            'status.required' => 'Please select a product status.',
        ]);

        $product->update($validated);

        return redirect()->route('products.index')->with('success', 'Product updated successfully.');
    }

    /**
     * Remove the specified product from storage (Soft Delete).
     */
    public function destroy(Product $product): RedirectResponse
    {
        $productName = $product->name;
        $product->delete();

        return redirect()->back()->with('success', "Product '{$productName}' moved to Recycle Bin.");
    }
}
