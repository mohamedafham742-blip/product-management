<script>
    import { useForm } from '@inertiajs/svelte';

    let { status = null, errors = {} } = $props();

    let showPassword = $state(false);

    const form = useForm({
        email: '',
        password: '',
        remember: false,
    });

    function handleSubmit(e) {
        e.preventDefault();
        $form.post('/login', {
            onFinish: () => {
                $form.reset('password');
            },
        });
    }
</script>

<svelte:head>
    <title>Login | Product Management System</title>
</svelte:head>

<div class="min-h-screen flex flex-col justify-center py-12 sm:px-6 lg:px-8 bg-gradient-to-b from-[#E7D6CC] via-[#F4ECE7] to-[#FAF7F4] text-[#2E2825] relative selection:bg-[#3D3835] selection:text-white">
    
    <!-- Top Subtle Accent -->
    <div class="absolute top-0 left-0 right-0 h-1.5 bg-[#3D3835]"></div>

    <div class="sm:mx-auto sm:w-full sm:max-w-md relative z-10 px-4 sm:px-0">
        
        <!-- Brand Header (Minimalist Warm Aesthetic) -->
        <div class="text-center mb-8">
            <div class="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-[#3D3835] text-white shadow-md shadow-[#3D3835]/15 mb-4">
                <svg class="w-7 h-7" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.75">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
            </div>
            <h1 class="text-2xl sm:text-3xl font-light tracking-wide text-[#2B2623] uppercase">
                Product System
            </h1>
        </div>

        <!-- Clean White Card Container -->
        <div class="bg-white/95 backdrop-blur-md border border-[#E3D6CC] rounded-2xl p-7 sm:p-9 shadow-xl shadow-[#D7C4BA]/30 relative">
            
            <!-- Status message if any -->
            {#if status}
                <div class="mb-5 p-3 rounded-xl bg-[#EAF5ED] border border-[#CDE5D4] text-[#2C6E3D] text-xs flex items-center gap-2">
                    <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    <span>{status}</span>
                </div>
            {/if}

            <!-- General Error / Failed Auth Message -->
            {#if $form.errors.email && !$form.errors.password && $form.errors.email.includes('records')}
                <div class="mb-5 p-3.5 rounded-xl bg-[#FDF0EE] border border-[#F6D0CA] text-[#A63628] text-xs flex items-center gap-2">
                    <svg class="w-4 h-4 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                    <span>{$form.errors.email}</span>
                </div>
            {/if}

            <form onsubmit={handleSubmit} class="space-y-4">
                <!-- Email Field -->
                <div>
                    <label for="email" class="block text-xs font-semibold uppercase tracking-wider text-[#5A4F48] mb-1.5">
                        Email Address
                    </label>
                    <div class="relative rounded-xl">
                        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9E9087]">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                            </svg>
                        </div>
                        <input
                            id="email"
                            type="email"
                            autocomplete="username"
                            required
                            placeholder="name@example.com"
                            bind:value={$form.email}
                            class="block w-full pl-10 pr-4 py-2.5 bg-[#FAF7F4] border {$form.errors.email && !$form.errors.email.includes('records') ? 'border-[#C95B4D] focus:ring-[#C95B4D]/20' : 'border-[#E5D8CF] focus:border-[#3D3835] focus:ring-[#3D3835]/15'} rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition-all focus:outline-none focus:ring-3"
                        />
                    </div>
                    {#if $form.errors.email && !$form.errors.email.includes('records')}
                        <p class="mt-1 text-xs text-[#A63628]">{$form.errors.email}</p>
                    {/if}
                </div>

                <!-- Password Field -->
                <div>
                    <div class="flex items-center justify-between mb-1.5">
                        <label for="password" class="block text-xs font-semibold uppercase tracking-wider text-[#5A4F48]">
                            Password
                        </label>
                    </div>
                    <div class="relative rounded-xl">
                        <div class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9E9087]">
                            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
                            </svg>
                        </div>
                        <input
                            id="password"
                            type={showPassword ? 'text' : 'password'}
                            autocomplete="current-password"
                            required
                            placeholder="••••••••"
                            bind:value={$form.password}
                            class="block w-full pl-10 pr-10 py-2.5 bg-[#FAF7F4] border {$form.errors.password ? 'border-[#C95B4D] focus:ring-[#C95B4D]/20' : 'border-[#E5D8CF] focus:border-[#3D3835] focus:ring-[#3D3835]/15'} rounded-xl text-[#2B2623] placeholder-[#A89C94] text-xs transition-all focus:outline-none focus:ring-3"
                        />
                        <button
                            type="button"
                            onclick={() => showPassword = !showPassword}
                            class="absolute inset-y-0 right-0 pr-3.5 flex items-center text-[#9E9087] hover:text-[#2B2623] focus:outline-none"
                            aria-label={showPassword ? 'Hide password' : 'Show password'}
                        >
                            {#if showPassword}
                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" />
                                </svg>
                            {:else}
                                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                </svg>
                            {/if}
                        </button>
                    </div>
                    {#if $form.errors.password}
                        <p class="mt-1 text-xs text-[#A63628]">{$form.errors.password}</p>
                    {/if}
                </div>

                <!-- Remember Me -->
                <div class="flex items-center justify-between pt-1">
                    <label class="flex items-center gap-2 cursor-pointer select-none">
                        <input
                            type="checkbox"
                            bind:checked={$form.remember}
                            class="w-3.5 h-3.5 rounded border-[#D8C7BC] text-[#3D3835] focus:ring-[#3D3835]/30"
                        />
                        <span class="text-xs text-[#6B5F57]">Remember me</span>
                    </label>
                </div>

                <!-- Charcoal Action Button (Assemble Style) -->
                <button
                    type="submit"
                    disabled={$form.processing}
                    class="w-full mt-2 flex items-center justify-center gap-2 py-3 px-4 rounded-xl text-xs font-semibold uppercase tracking-widest text-white bg-[#3D3835] hover:bg-[#272321] active:scale-[0.99] disabled:opacity-60 shadow-md shadow-[#3D3835]/20 transition-all duration-150 cursor-pointer"
                >
                    {#if $form.processing}
                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Authenticating...</span>
                    {:else}
                        <span>Sign In</span>
                    {/if}
                </button>
            </form>

            <!-- Create an Account Link -->
            <div class="mt-5 pt-4 border-t border-[#EADBCE] text-center">
                <p class="text-xs text-[#7D716A]">
                    Don't have an account? 
                    <a href="/register" class="text-[#3D3835] hover:text-[#000000] font-semibold underline underline-offset-2 ml-1 transition">
                        Register here
                    </a>
                </p>
            </div>

        </div>
    </div>
</div>
