import adapter from '@sveltejs/adapter-static';
import { relative, sep } from 'node:path';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [
    sveltekit({
      compilerOptions: {
        // defaults to rune mode for the project, except for `node_modules`. Can be removed in svelte 6.
        runes: ({ filename }) => {
          const relativePath = relative(import.meta.dirname, filename);
          const pathSegments = relativePath.toLowerCase().split(sep);
          const isExternalLibrary = pathSegments.includes('node_modules');

          return isExternalLibrary ? undefined : true;
        },
      },
      csp: {
        mode: 'hash',
        directives: {
          'default-src': ['self'],
          'base-uri': ['self'],
          'form-action': ['none'],
          'object-src': ['none'],
          'script-src': ['self'],
          'style-src': ['self', 'unsafe-inline'],
          'img-src': ['self', 'data:'],
          'font-src': ['self'],
          'connect-src': ['self'],
          'upgrade-insecure-requests': true,
        },
      },

      adapter: adapter({
        pages: 'build',
        assets: 'build',
        fallback: undefined,
        precompress: true,
        strict: true,
      }),
    }),
  ],
});
