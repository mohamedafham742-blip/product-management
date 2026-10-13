import '../css/app.css';
import { createInertiaApp } from '@inertiajs/svelte';
import { mount } from 'svelte';

createInertiaApp({
    resolve: (name) => {
        const pages = import.meta.glob('./Pages/**/*.svelte', { eager: true });
        const page = pages[`./Pages/${name}.svelte`];
        if (!page) {
            throw new Error(`Page "./Pages/${name}.svelte" not found.`);
        }
        return page;
    },
    setup({ el, App, props }) {
        mount(App, { target: el, props });
    },
});
