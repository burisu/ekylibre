// Minimal HTTP client on fetch, with the subset of the axios API used by the
// application: get/post/request resolving to { data, status, headers } and
// rejecting with an error carrying the same `response` for non-2xx statuses.

function csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.content : null;
}

function buildUrl(url, params) {
    if (!params || Object.keys(params).length === 0) return url;
    const target = new URL(url, window.location.href);
    Object.entries(params).forEach(([key, value]) => {
        if (value === undefined || value === null) return;
        if (Array.isArray(value)) {
            value.forEach((item) => target.searchParams.append(`${key}[]`, item));
        } else {
            target.searchParams.append(key, value);
        }
    });
    return target.toString();
}

function buildBody(data, headers) {
    if (data === undefined || data === null) return undefined;
    if (data instanceof FormData || data instanceof URLSearchParams || data instanceof Blob || typeof data === 'string') {
        return data;
    }
    headers['Content-Type'] = 'application/json';
    return JSON.stringify(data);
}

async function parseData(response) {
    const contentType = response.headers.get('content-type') || '';
    if (response.status === 204) return null;
    if (contentType.includes('application/json')) return response.json();
    return response.text();
}

export async function request({ method = 'get', url, params, data, headers = {} }) {
    const requestHeaders = { Accept: 'application/json, text/html, */*', ...headers };
    const verb = method.toUpperCase();
    if (verb !== 'GET' && verb !== 'HEAD' && csrfToken()) {
        requestHeaders['X-CSRF-Token'] = csrfToken();
    }
    const body = buildBody(data, requestHeaders);
    const response = await fetch(buildUrl(url, params), {
        method: verb,
        headers: requestHeaders,
        body,
        credentials: 'same-origin',
    });
    const result = {
        data: await parseData(response),
        status: response.status,
        headers: Object.fromEntries([...response.headers.entries()].map(([key, value]) => [key.toLowerCase(), value])),
    };
    if (!response.ok) {
        const error = new Error(`Request failed with status code ${response.status}`);
        error.response = result;
        throw error;
    }
    return result;
}

export function get(url, config = {}) {
    return request({ ...config, method: 'get', url });
}

export function post(url, data, config = {}) {
    return request({ ...config, method: 'post', url, data });
}

export default { request, get, post };
