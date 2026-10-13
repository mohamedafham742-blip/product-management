<script>
    import { useForm, router, page } from '@inertiajs/svelte';

    let {
        products = { data: [], links: [] },
        filters = { search: '', status: 'all' },
        stats = { total: 0, active: 0, inactive: 0, total_stock: 0 },
        flash = {}
    } = $props();

    // Search and Status filters
    let search = $state('');
    let statusFilter = $state('all');
    let searchTimeout = null;

    $effect(() => {
        search = filters.search || '';
        statusFilter = filters.status || 'all';
    });

    // Real-time auto-sync: automatically update product list when modified from mobile app
    $effect(() => {
        const interval = setInterval(() => {
            if (
                !showCreateModal &&
                !showEditModal &&
                !showViewModal &&
                !showDeleteModal &&
                !isDeleting &&
                (!search || search.trim() === '')
            ) {
                router.reload({
                    only: ['products', 'stats'],
                    preserveScroll: true,
                    preserveState: true,
                });
            }
        }, 2000);

        return () => {
            clearInterval(interval);
        };
    });

    function applyFilters() {
        router.get('/products', {
            search: search || undefined,
            status: statusFilter !== 'all' ? statusFilter : undefined,
        }, {
            preserveState: true,
            replace: true,
        });
    }

    function handleSearchInput() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(() => {
            applyFilters();
        }, 300);
    }

    function handleStatusChange(newStatus) {
        statusFilter = newStatus;
        applyFilters();
    }

    // Modals state
    let showCreateModal = $state(false);
    let showEditModal = $state(false);
    let showViewModal = $state(false);
    let showDeleteModal = $state(false);

    let viewingProduct = $state(null);
    let editingProduct = $state(null);
    let deletingProduct = $state(null);
    let isDeleting = $state(false);

    // Toast notification state
    let toastMessage = $state('');
    let toastType = $state('success'); // 'success' | 'error'
    let toastTimeout = null;

    function showToast(msg, type = 'success') {
        toastMessage = msg;
        toastType = type;
        if (toastTimeout) clearTimeout(toastTimeout);
        toastTimeout = setTimeout(() => {
            toastMessage = '';
        }, 4000);
    }

    $effect(() => {
        if (flash?.success) {
            showToast(flash.success, 'success');
        } else if (flash?.error) {
            showToast(flash.error, 'error');
        }
    });

    // Create Form Store
    const createForm = useForm({
        name: '',
        sku: '',
        description: '',
        price: '',
        quantity: '',
        status: 'active',
    });

    // Edit Form Store
    const editForm = useForm({
        name: '',
        sku: '',
        description: '',
        price: '',
        quantity: '',
        status: 'active',
    });

    function openCreateModal() {
        $createForm.reset();
        $createForm.clearErrors();
        showCreateModal = true;
    }

    function submitCreate() {
        $createForm.post('/products', {
            preserveScroll: true,
            onSuccess: () => {
                showCreateModal = false;
                $createForm.reset();
                showToast('Product added to catalog successfully.');
            },
            onError: () => {
                showToast('Failed to create product. Please check form errors.', 'error');
            }
        });
    }

    function openEditModal(product) {
        editingProduct = product;
        $editForm.name = product.name;
        $editForm.sku = product.sku;
        $editForm.description = product.description || '';
        $editForm.price = product.price;
        $editForm.quantity = product.quantity;
        $editForm.status = product.status;
        $editForm.clearErrors();
        showEditModal = true;
    }

    function submitEdit() {
        if (!editingProduct) return;
        $editForm.put(`/products/${editingProduct.id}`, {
            preserveScroll: true,
            onSuccess: () => {
                showEditModal = false;
                editingProduct = null;
                showToast('Product updated successfully.');
            },
            onError: () => {
                showToast('Failed to update product. Please check form errors.', 'error');
            }
        });
    }

    function openViewModal(product) {
        viewingProduct = product;
        showViewModal = true;
    }

    function openDeleteModal(product) {
        deletingProduct = product;
        isDeleting = false;
        showDeleteModal = true;
    }

    function cancelDelete() {
        if (isDeleting) return;
        showDeleteModal = false;
        deletingProduct = null;
    }

    function submitDelete() {
        if (!deletingProduct || isDeleting) return;
        isDeleting = true;
        const targetProduct = deletingProduct;

        router.delete(`/products/${targetProduct.id}`, {
            preserveScroll: true,
            preserveState: true,
            onSuccess: () => {
                showToast(`Product '${targetProduct.name}' moved to Recycle Bin.`);
            },
            onError: () => {
                showToast('Failed to delete product. Please try again.', 'error');
            },
            onFinish: () => {
                isDeleting = false;
                showDeleteModal = false;
                deletingProduct = null;
            },
        });
    }

    function handleLogout() {
        router.post('/logout');
    }

    function formatPrice(val) {
        const num = parseFloat(val);
        return isNaN(num) ? 'Rs. 0.00' : `Rs. ${num.toFixed(2)}`;
    }
</script>

<svelte:head>
    <title>Products | Product Management System</title>
</svelte:head>

<div class="min-h-screen bg-[#FAF7F4] text-[#2E2825] flex flex-col selection:bg-[#3D3835] selection:text-white relative">

    <!-- Toast Notification Banner -->
    {#if toastMessage}
        <div class="fixed top-5 right-5 z-50 flex items-center gap-3 px-4 py-3 rounded-2xl shadow-xl border animate-in slide-in-from-top-3 duration-200 {toastType === 'error' ? 'bg-[#FAF0EE] border-[#EBCAC4] text-[#A33B2E]' : 'bg-[#EAF5ED] border-[#CDE5D4] text-[#2C6E3D]'}">
            {#if toastType === 'error'}
                <svg class="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
            {:else}
                <svg class="w-5 h-5 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                </svg>
            {/if}
            <span class="text-xs font-semibold">{toastMessage}</span>
            <button
                type="button"
                aria-label="Dismiss notification"
                onclick={() => toastMessage = ''}
                class="ml-2 text-current opacity-60 hover:opacity-100 transition cursor-pointer"
            >
                <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>
    {/if}

    <!-- Top Navigation Bar (Assemble Clean Aesthetic) -->
    <header class="border-b border-[#E7DCD2] bg-white/90 backdrop-blur-md sticky top-0 z-30">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            
            <!-- Brand Logo & Navigation Links -->
            <div class="flex items-center gap-8">
                <a href="/dashboard" class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-[#3D3835] flex items-center justify-center text-white shadow-sm">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                        </svg>
                    </div>
                    <div>
                        <div class="font-semibold text-sm tracking-wide text-[#2B2623] uppercase">
                            Product System
                        </div>
                    </div>
                </a>

                <!-- Nav Menu Links -->
                <nav class="hidden md:flex items-center gap-1">
                    <a
                        href="/dashboard"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#7D716A] hover:text-[#2B2623] hover:bg-[#F4ECE7] transition"
                    >
                        Dashboard
                    </a>
                    <a
                        href="/products"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-semibold text-[#2B2623] bg-[#EFE7E1] border border-[#DCCEC4] transition"
                    >
                        Products
                    </a>
                    <a
                        href="/recycle-bin"
                        class="px-3.5 py-1.5 rounded-lg text-xs font-medium text-[#7D716A] hover:text-[#2B2623] hover:bg-[#F4ECE7] transition"
                    >
                        Recycle Bin
                    </a>
                </nav>
            </div>

            <!-- Actions & Logout -->
            <div class="flex items-center gap-3">
                <button
                    type="button"
                    onclick={handleLogout}
                    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold text-[#8F3528] bg-[#FAF0EE] hover:bg-[#F5E2DE] border border-[#EBCAC4] transition-all cursor-pointer"
                >
                    <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                    <span>Sign Out</span>
                </button>
            </div>
        </div>
    </header>

    <!-- Main Content Area -->
    <main class="flex-1 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full">
        
        <!-- Summary Stats Cards -->
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm">
                <div class="text-[11px] font-semibold text-[#8A7C73] uppercase tracking-wider">Total Products</div>
                <div class="text-2xl font-semibold text-[#2B2623] mt-1">{stats.total}</div>
                <div class="text-[11px] text-[#9E9087] mt-0.5">Catalog inventory count</div>
            </div>

            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm">
                <div class="text-[11px] font-semibold text-[#2C6E3D] uppercase tracking-wider flex items-center gap-1.5">
                    <span class="w-2 h-2 rounded-full bg-[#2C6E3D]"></span> Active Items
                </div>
                <div class="text-2xl font-semibold text-[#2B2623] mt-1">{stats.active}</div>
                <div class="text-[11px] text-[#9E9087] mt-0.5">Available for sales</div>
            </div>

            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm">
                <div class="text-[11px] font-semibold text-[#A66D24] uppercase tracking-wider flex items-center gap-1.5">
                    <span class="w-2 h-2 rounded-full bg-[#C2822B]"></span> Inactive Items
                </div>
                <div class="text-2xl font-semibold text-[#2B2623] mt-1">{stats.inactive}</div>
                <div class="text-[11px] text-[#9E9087] mt-0.5">Hidden / archived</div>
            </div>

            <div class="bg-white border border-[#E5D8CF] rounded-2xl p-5 shadow-sm">
                <div class="text-[11px] font-semibold text-[#3D3835] uppercase tracking-wider">Total Stock Units</div>
                <div class="text-2xl font-semibold text-[#2B2623] mt-1">{stats.total_stock}</div>
                <div class="text-[11px] text-[#9E9087] mt-0.5">Units in warehouse</div>
            </div>
        </div>

        <!-- Section Header & Controls -->
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4 mb-6">
            <div>
                <h1 class="text-2xl sm:text-3xl font-light tracking-wide text-[#2B2623]">
                    Product Catalog
                </h1>
                <p class="mt-1 text-xs text-[#8A7C73]">
                    Manage stock, pricing, SKU references, and product status
                </p>
            </div>

            <!-- Action Button -->
            <button
                type="button"
                onclick={openCreateModal}
                class="inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition shadow-xs cursor-pointer active:scale-[0.99]"
            >
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                </svg>
                <span>Add New Product</span>
            </button>
        </div>

        <!-- Filters Bar: Search & Status Selector -->
        <div class="bg-white border border-[#E5D8CF] rounded-2xl p-4 mb-6 shadow-sm flex flex-col sm:flex-row gap-4 items-center justify-between">
            
            <!-- Search Input -->
            <div class="relative w-full sm:w-80">
                <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9E9087]">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                    </svg>
                </div>
                <input
                    type="text"
                    placeholder="Search by Name, SKU or description..."
                    bind:value={search}
                    oninput={handleSearchInput}
                    class="block w-full pl-10 pr-4 py-2 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                />
            </div>

            <!-- Status Tabs Filter -->
            <div class="flex items-center gap-1.5 w-full sm:w-auto bg-[#FAF7F4] p-1 rounded-xl border border-[#E8DDD4]">
                <button
                    type="button"
                    onclick={() => handleStatusChange('all')}
                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition cursor-pointer {statusFilter === 'all' ? 'bg-[#3D3835] text-white shadow-xs' : 'text-[#7D7068] hover:text-[#2B2623]'}"
                >
                    All ({stats.total})
                </button>
                <button
                    type="button"
                    onclick={() => handleStatusChange('active')}
                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition cursor-pointer {statusFilter === 'active' ? 'bg-[#3D3835] text-white shadow-xs' : 'text-[#7D7068] hover:text-[#2B2623]'}"
                >
                    Active ({stats.active})
                </button>
                <button
                    type="button"
                    onclick={() => handleStatusChange('inactive')}
                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition cursor-pointer {statusFilter === 'inactive' ? 'bg-[#3D3835] text-white shadow-xs' : 'text-[#7D7068] hover:text-[#2B2623]'}"
                >
                    Inactive ({stats.inactive})
                </button>
            </div>
        </div>

        <!-- Products Table -->
        <div class="bg-white border border-[#E5D8CF] rounded-2xl overflow-hidden shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="border-b border-[#EAE0D7] bg-[#FAF6F2] text-[11px] uppercase tracking-wider font-semibold text-[#7D7068]">
                            <th class="py-3.5 px-5">Product &amp; SKU</th>
                            <th class="py-3.5 px-5">Price</th>
                            <th class="py-3.5 px-5">Stock Quantity</th>
                            <th class="py-3.5 px-5">Status</th>
                            <th class="py-3.5 px-5 text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-[#F2EAE3] text-xs">
                        {#if products.data.length === 0}
                            <tr>
                                <td colspan="5" class="py-14 text-center text-[#8A7C73]">
                                    <div class="w-12 h-12 rounded-2xl bg-[#F5ECE5] text-[#8C7D75] mx-auto mb-3 flex items-center justify-center">
                                        <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                                        </svg>
                                    </div>
                                    <div class="font-medium text-[#2B2623] text-sm">No products found</div>
                                    <p class="text-xs text-[#8A7C73] mt-1 max-w-sm mx-auto">
                                        {search ? `No products matching "${search}"` : 'Get started by creating your first product.'}
                                    </p>
                                    {#if !search}
                                        <button
                                            type="button"
                                            onclick={openCreateModal}
                                            class="mt-4 inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition"
                                        >
                                            <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                                            </svg>
                                            <span>Add Product</span>
                                        </button>
                                    {/if}
                                </td>
                            </tr>
                        {:else}
                            {#each products.data as item}
                                <tr class="hover:bg-[#FAF6F2] transition">
                                    <td class="py-4 px-5">
                                        <div class="flex items-center gap-3">
                                            <div class="w-9 h-9 rounded-xl bg-[#F2E8E0] border border-[#E2D4C8] text-[#3D3835] flex items-center justify-center flex-shrink-0">
                                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                                                </svg>
                                            </div>
                                            <div>
                                                <div class="font-medium text-[#2B2623] text-xs flex items-center gap-2">
                                                    <span>{item.name}</span>
                                                    <span class="font-mono text-[10px] px-1.5 py-0.5 rounded bg-[#ECE3DC] text-[#5C5049] border border-[#DCCEC2]">
                                                        {item.sku}
                                                    </span>
                                                </div>
                                                <p class="text-[11px] text-[#8C7F78] line-clamp-1 max-w-xs mt-0.5">
                                                    {item.description || 'No description provided'}
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td class="py-4 px-5 font-mono text-xs font-semibold text-[#2B2623]">
                                        {formatPrice(item.price)}
                                    </td>
                                    <td class="py-4 px-5">
                                        <div class="flex items-center gap-2">
                                            <span class="font-medium text-xs text-[#2B2623]">{item.quantity}</span>
                                            {#if item.quantity <= 0}
                                                <span class="px-1.5 py-0.5 rounded text-[10px] bg-[#FAF0EE] text-[#8F3528] border border-[#EBCAC4] font-medium">
                                                    Out of Stock
                                                </span>
                                            {:else if item.quantity < 10}
                                                <span class="px-1.5 py-0.5 rounded text-[10px] bg-[#FFF8EB] text-[#9E6517] border border-[#F3DEB8] font-medium">
                                                    Low Stock
                                                </span>
                                            {:else}
                                                <span class="px-1.5 py-0.5 rounded text-[10px] bg-[#EAF5ED] text-[#2C6E3D] border border-[#CDE5D4] font-medium">
                                                    In Stock
                                                </span>
                                            {/if}
                                        </div>
                                    </td>
                                    <td class="py-4 px-5">
                                        {#if item.status === 'active'}
                                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-[#EAF5ED] text-[#2C6E3D] border border-[#CDE5D4]">
                                                <span class="w-1.5 h-1.5 rounded-full bg-[#2C6E3D]"></span>
                                                Active
                                            </span>
                                        {:else}
                                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-[#F5ECE6] text-[#7D7068] border border-[#E0D2C7]">
                                                <span class="w-1.5 h-1.5 rounded-full bg-[#8C7D75]"></span>
                                                Inactive
                                            </span>
                                        {/if}
                                    </td>
                                    <td class="py-4 px-5 text-right">
                                        <div class="flex items-center justify-end gap-1.5">
                                            <!-- View Button -->
                                            <button
                                                type="button"
                                                title="View Details"
                                                onclick={() => openViewModal(item)}
                                                class="p-1.5 rounded-lg text-[#6B5E57] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer"
                                            >
                                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                </svg>
                                            </button>

                                            <!-- Edit Button -->
                                            <button
                                                type="button"
                                                title="Edit Product"
                                                onclick={() => openEditModal(item)}
                                                class="p-1.5 rounded-lg text-[#3D3835] hover:text-[#111] hover:bg-[#EFE6DE] transition cursor-pointer"
                                            >
                                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                                </svg>
                                            </button>

                                            <!-- Delete Button -->
                                            <button
                                                type="button"
                                                title="Delete Product"
                                                onclick={(e) => { e.stopPropagation(); openDeleteModal(item); }}
                                                class="p-1.5 rounded-lg text-[#A33B2E] hover:text-[#7A1E14] hover:bg-[#FDECEB] transition cursor-pointer"
                                            >
                                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                                    <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                                </svg>
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            {/each}
                        {/if}
                    </tbody>
                </table>
            </div>

            <!-- Pagination Links -->
            {#if products.links && products.links.length > 3}
                <div class="py-3.5 px-5 border-t border-[#EAE0D7] bg-[#FAF6F2] flex flex-col sm:flex-row items-center justify-between gap-3">
                    <div class="text-xs text-[#8A7C73]">
                        Showing {products.data.length} records
                    </div>
                    <div class="flex items-center gap-1.5">
                        {#each products.links as link}
                            {#if link.url}
                                <a
                                    href={link.url}
                                    class="px-3 py-1.5 rounded-lg text-xs font-medium transition {link.active ? 'bg-[#3D3835] text-white' : 'bg-white text-[#5C5049] hover:bg-[#F2ECE6] border border-[#E5D8CF]'}"
                                >
                                    {@html link.label}
                                </a>
                            {:else}
                                <span class="px-3 py-1.5 rounded-lg text-xs font-medium text-[#B5A79E] bg-[#FAF6F2]">
                                    {@html link.label}
                                </span>
                            {/if}
                        {/each}
                    </div>
                </div>
            {/if}
        </div>

    </main>

    <!-- Footer -->
    <footer class="border-t border-[#E7DCD2] py-4 mt-auto bg-white/60">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between text-xs text-[#8A7C73] gap-2">
            <div>
                Product Management System
            </div>
            <div>
                Laravel &bull; Svelte 5 &bull; MySQL
            </div>
        </div>
    </footer>
</div>

<!-- ================= MODALS ================= -->

<!-- 1. CREATE PRODUCT MODAL -->
{#if showCreateModal}
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-lg w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <div class="flex items-center justify-between pb-4 border-b border-[#F0E6DE] mb-5">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-[#3D3835] text-white flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Add New Product</h3>
                        <p class="text-[11px] text-[#8A7C73]">Enter product details for inventory catalog</p>
                    </div>
                </div>
                <button
                    type="button"
                    aria-label="Close"
                    onclick={() => showCreateModal = false}
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <form onsubmit={(e) => { e.preventDefault(); submitCreate(); }} class="space-y-4 text-xs">
                <!-- Name -->
                <div>
                    <label for="create_name" class="block font-medium text-[#2B2623] mb-1">
                        Product Name <span class="text-rose-500">*</span>
                    </label>
                    <input
                        id="create_name"
                        type="text"
                        placeholder="e.g. Minimalist Linen Notebook"
                        bind:value={$createForm.name}
                        class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                    />
                    {#if $createForm.errors.name}
                        <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.name}</p>
                    {/if}
                </div>

                <!-- SKU & Price Row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="create_sku" class="block font-medium text-[#2B2623] mb-1">
                            SKU / Code <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="create_sku"
                            type="text"
                            placeholder="e.g. PRD-NB-001"
                            bind:value={$createForm.sku}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs uppercase font-mono transition focus:outline-none"
                        />
                        {#if $createForm.errors.sku}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.sku}</p>
                        {/if}
                    </div>

                    <div>
                        <label for="create_price" class="block font-medium text-[#2B2623] mb-1">
                            Price (Rs.) <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="create_price"
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="29.99"
                            bind:value={$createForm.price}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                        />
                        {#if $createForm.errors.price}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.price}</p>
                        {/if}
                    </div>
                </div>

                <!-- Quantity & Status Row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="create_quantity" class="block font-medium text-[#2B2623] mb-1">
                            Stock Quantity <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="create_quantity"
                            type="number"
                            min="0"
                            placeholder="50"
                            bind:value={$createForm.quantity}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                        />
                        {#if $createForm.errors.quantity}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.quantity}</p>
                        {/if}
                    </div>

                    <div>
                        <label for="create_status" class="block font-medium text-[#2B2623] mb-1">
                            Status <span class="text-rose-500">*</span>
                        </label>
                        <select
                            id="create_status"
                            bind:value={$createForm.status}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                        >
                            <option value="active">Active (Visible)</option>
                            <option value="inactive">Inactive (Hidden)</option>
                        </select>
                        {#if $createForm.errors.status}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.status}</p>
                        {/if}
                    </div>
                </div>

                <!-- Description -->
                <div>
                    <label for="create_desc" class="block font-medium text-[#2B2623] mb-1">
                        Description <span class="text-[#8A7C73] font-normal">(Optional)</span>
                    </label>
                    <textarea
                        id="create_desc"
                        rows="3"
                        placeholder="Product description, material specifications, notes..."
                        bind:value={$createForm.description}
                        class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition focus:outline-none"
                    ></textarea>
                    {#if $createForm.errors.description}
                        <p class="mt-1 text-[11px] text-[#B83B2B]">{$createForm.errors.description}</p>
                    {/if}
                </div>

                <!-- Buttons -->
                <div class="flex items-center justify-end gap-2.5 pt-4 border-t border-[#F0E6DE]">
                    <button
                        type="button"
                        onclick={() => showCreateModal = false}
                        class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        disabled={$createForm.processing}
                        class="px-4 py-2 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition cursor-pointer disabled:opacity-50"
                    >
                        {$createForm.processing ? 'Saving...' : 'Save Product'}
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- 2. EDIT PRODUCT MODAL -->
{#if showEditModal && editingProduct}
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-lg w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <div class="flex items-center justify-between pb-4 border-b border-[#F0E6DE] mb-5">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-[#3D3835] text-white flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Edit Product #{editingProduct.id}</h3>
                        <p class="text-[11px] text-[#8A7C73]">Update inventory specifications</p>
                    </div>
                </div>
                <button
                    type="button"
                    aria-label="Close"
                    onclick={() => showEditModal = false}
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <form onsubmit={(e) => { e.preventDefault(); submitEdit(); }} class="space-y-4 text-xs">
                <!-- Name -->
                <div>
                    <label for="edit_name" class="block font-medium text-[#2B2623] mb-1">
                        Product Name <span class="text-rose-500">*</span>
                    </label>
                    <input
                        id="edit_name"
                        type="text"
                        bind:value={$editForm.name}
                        class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                    />
                    {#if $editForm.errors.name}
                        <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.name}</p>
                    {/if}
                </div>

                <!-- SKU & Price Row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="edit_sku" class="block font-medium text-[#2B2623] mb-1">
                            SKU / Code <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="edit_sku"
                            type="text"
                            bind:value={$editForm.sku}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] uppercase font-mono text-xs transition focus:outline-none"
                        />
                        {#if $editForm.errors.sku}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.sku}</p>
                        {/if}
                    </div>

                    <div>
                        <label for="edit_price" class="block font-medium text-[#2B2623] mb-1">
                            Price (Rs.) <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="edit_price"
                            type="number"
                            step="0.01"
                            min="0"
                            bind:value={$editForm.price}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                        />
                        {#if $editForm.errors.price}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.price}</p>
                        {/if}
                    </div>
                </div>

                <!-- Quantity & Status Row -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                        <label for="edit_quantity" class="block font-medium text-[#2B2623] mb-1">
                            Stock Quantity <span class="text-rose-500">*</span>
                        </label>
                        <input
                            id="edit_quantity"
                            type="number"
                            min="0"
                            bind:value={$editForm.quantity}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                        />
                        {#if $editForm.errors.quantity}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.quantity}</p>
                        {/if}
                    </div>

                    <div>
                        <label for="edit_status" class="block font-medium text-[#2B2623] mb-1">
                            Status <span class="text-rose-500">*</span>
                        </label>
                        <select
                            id="edit_status"
                            bind:value={$editForm.status}
                            class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                        >
                            <option value="active">Active (Visible)</option>
                            <option value="inactive">Inactive (Hidden)</option>
                        </select>
                        {#if $editForm.errors.status}
                            <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.status}</p>
                        {/if}
                    </div>
                </div>

                <!-- Description -->
                <div>
                    <label for="edit_desc" class="block font-medium text-[#2B2623] mb-1">
                        Description
                    </label>
                    <textarea
                        id="edit_desc"
                        rows="3"
                        bind:value={$editForm.description}
                        class="block w-full px-3.5 py-2.5 bg-[#FAF7F4] border border-[#E5D8CF] focus:border-[#3D3835] focus:ring-2 focus:ring-[#3D3835]/15 rounded-xl text-[#2B2623] text-xs transition focus:outline-none"
                    ></textarea>
                    {#if $editForm.errors.description}
                        <p class="mt-1 text-[11px] text-[#B83B2B]">{$editForm.errors.description}</p>
                    {/if}
                </div>

                <!-- Buttons -->
                <div class="flex items-center justify-end gap-2.5 pt-4 border-t border-[#F0E6DE]">
                    <button
                        type="button"
                        onclick={() => showEditModal = false}
                        class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer"
                    >
                        Cancel
                    </button>
                    <button
                        type="submit"
                        disabled={$editForm.processing}
                        class="px-4 py-2 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition cursor-pointer disabled:opacity-50"
                    >
                        {$editForm.processing ? 'Updating...' : 'Update Product'}
                    </button>
                </div>
            </form>
        </div>
    </div>
{/if}

<!-- 3. VIEW PRODUCT DETAILS MODAL -->
{#if showViewModal && viewingProduct}
    <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs">
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-lg w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <div class="flex items-center justify-between pb-4 border-b border-[#F0E6DE] mb-5">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-[#F4ECE6] border border-[#E5D6CC] text-[#3D3835] flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Product Details</h3>
                        <p class="text-[11px] text-[#8A7C73]">Record ID #{viewingProduct.id}</p>
                    </div>
                </div>
                <button
                    type="button"
                    aria-label="Close"
                    onclick={() => showViewModal = false}
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <div class="space-y-3.5 text-xs">
                <div class="bg-[#FAF6F2] p-4 rounded-xl border border-[#EAE0D7]">
                    <div class="text-[11px] uppercase font-semibold tracking-wider text-[#8A7C73]">Product Name</div>
                    <div class="text-base font-semibold text-[#2B2623] mt-0.5">{viewingProduct.name}</div>
                    <div class="font-mono text-xs text-[#5C5049] mt-1 flex items-center gap-2">
                        <span class="px-1.5 py-0.5 rounded bg-white border border-[#E0D2C7] font-semibold">{viewingProduct.sku}</span>
                    </div>
                </div>

                <div class="grid grid-cols-3 gap-3">
                    <div class="p-3 bg-white border border-[#EAE0D7] rounded-xl">
                        <div class="text-[10px] uppercase font-semibold text-[#8A7C73]">Unit Price</div>
                        <div class="text-sm font-semibold text-[#2B2623] font-mono mt-0.5">{formatPrice(viewingProduct.price)}</div>
                    </div>
                    <div class="p-3 bg-white border border-[#EAE0D7] rounded-xl">
                        <div class="text-[10px] uppercase font-semibold text-[#8A7C73]">Stock Units</div>
                        <div class="text-sm font-semibold text-[#2B2623] mt-0.5">{viewingProduct.quantity}</div>
                    </div>
                    <div class="p-3 bg-white border border-[#EAE0D7] rounded-xl">
                        <div class="text-[10px] uppercase font-semibold text-[#8A7C73]">Status</div>
                        <div class="text-xs font-semibold capitalize mt-0.5 {viewingProduct.status === 'active' ? 'text-[#2C6E3D]' : 'text-[#7D7068]'}">
                            {viewingProduct.status}
                        </div>
                    </div>
                </div>

                <div>
                    <div class="text-[11px] font-semibold text-[#8A7C73] uppercase tracking-wider mb-1">Description</div>
                    <p class="p-3 rounded-xl bg-[#FAF7F4] border border-[#EAE0D7] text-xs text-[#5C5049] leading-relaxed">
                        {viewingProduct.description || 'No description provided for this product.'}
                    </p>
                </div>
            </div>

            <div class="flex items-center justify-end gap-2.5 pt-5 border-t border-[#F0E6DE] mt-5">
                <button
                    type="button"
                    onclick={() => showViewModal = false}
                    class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer"
                >
                    Close
                </button>
                <button
                    type="button"
                    onclick={() => {
                        const p = viewingProduct;
                        showViewModal = false;
                        openEditModal(p);
                    }}
                    class="px-4 py-2 rounded-xl text-xs font-semibold text-white bg-[#3D3835] hover:bg-[#2B2623] transition cursor-pointer"
                >
                    Edit Product
                </button>
            </div>
        </div>
    </div>
{/if}

<!-- 4. DELETE CONFIRMATION MODAL -->
{#if showDeleteModal && deletingProduct}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-xs"
        onclick={(e) => { if (e.target === e.currentTarget && !isDeleting) cancelDelete(); }}
        onkeydown={(e) => { if (e.key === 'Escape' && !isDeleting) cancelDelete(); }}
        tabindex="-1"
        role="dialog"
        aria-modal="true"
    >
        <div class="bg-white border border-[#E5D8CF] rounded-2xl max-w-md w-full p-6 shadow-xl animate-in fade-in zoom-in-95 duration-150">
            <!-- Header with Icon & Close 'X' Button -->
            <div class="flex items-start justify-between pb-3 mb-3 border-b border-[#F0E6DE]">
                <div class="flex items-center gap-3.5">
                    <div class="w-10 h-10 rounded-xl bg-[#FAF0EE] border border-[#EBCAC4] text-[#A33B2E] flex items-center justify-center flex-shrink-0">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                    </div>
                    <div>
                        <h3 class="font-semibold text-sm text-[#2B2623]">Delete Product</h3>
                        <p class="text-[11px] text-[#8A7C73]">Move product to Recycle Bin</p>
                    </div>
                </div>
                <button
                    type="button"
                    disabled={isDeleting}
                    onclick={cancelDelete}
                    aria-label="Close"
                    class="p-1.5 rounded-lg text-[#8A7C73] hover:text-[#2B2623] hover:bg-[#F2ECE6] transition cursor-pointer disabled:opacity-40"
                >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <!-- Notice / Warning Text -->
            <p class="text-xs text-[#5C5049] leading-relaxed mb-4">
                Are you sure you want to remove <strong class="text-[#2B2623] font-semibold">{deletingProduct.name}</strong> ({deletingProduct.sku})?
                This product will be safely moved to the <strong class="font-semibold text-[#3D3835]">Recycle Bin</strong> (Soft Deleted) and can be restored anytime.
            </p>

            <!-- Buttons: Clear and Unambiguous -->
            <div class="flex items-center justify-end gap-2.5 pt-4 border-t border-[#F0E6DE]">
                <!-- CANCEL BUTTON: Explicitly Keeps Product and Cancels Action -->
                <button
                    type="button"
                    disabled={isDeleting}
                    onclick={cancelDelete}
                    class="px-4 py-2 rounded-xl text-xs font-semibold text-[#6E6159] hover:bg-[#F2ECE6] border border-[#E5D8CF] transition cursor-pointer disabled:opacity-50"
                >
                    Cancel (Keep Product)
                </button>

                <!-- DELETE BUTTON: Explicitly Deletes with spinner and disabled state -->
                <button
                    type="button"
                    disabled={isDeleting}
                    onclick={submitDelete}
                    class="px-4 py-2.5 rounded-xl text-xs font-semibold text-white bg-[#A33B2E] hover:bg-[#852C21] transition cursor-pointer flex items-center gap-2 disabled:opacity-60 shadow-sm"
                >
                    {#if isDeleting}
                        <svg class="w-3.5 h-3.5 animate-spin" viewBox="0 0 24 24" fill="none">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Deleting...</span>
                    {:else}
                        <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                        <span>Yes, Delete Product</span>
                    {/if}
                </button>
            </div>
        </div>
    </div>
{/if}
