import { ProxyAgent, setGlobalDispatcher } from 'undici';

declare global {
  // eslint-disable-next-line no-var
  var __hivechatProxyInitialized: boolean | undefined;
}

const proxy = process.env.HTTPS_PROXY
  ?? process.env.https_proxy
  ?? process.env.HTTP_PROXY
  ?? process.env.http_proxy;

if (proxy && !globalThis.__hivechatProxyInitialized) {
  const noProxy = process.env.NO_PROXY ?? process.env.no_proxy;
  const agent = new ProxyAgent({
    uri: proxy,
    ...(noProxy ? { noProxy } : {}),
  });

  setGlobalDispatcher(agent);
  globalThis.__hivechatProxyInitialized = true;
}

export {};
