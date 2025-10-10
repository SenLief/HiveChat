import { HttpsProxyAgent } from 'https-proxy-agent';
import { Dispatcher, ProxyAgent } from 'undici';

/**
 * 获取系统代理配置的 fetch 选项
 * 自动检测环境变量中的代理设置
 * @returns fetch 选项，如果不需要代理则返回空对象
 */
let cachedProxyUrl: string | null = null;
let cachedDispatcher: Dispatcher | null = null;
let cachedHttpsAgent: any | null = null;

export function getProxyFetchOptions(): { dispatcher?: Dispatcher; agent?: any } {
  // 检测常见的代理环境变量
  const proxyUrl = process.env.HTTPS_PROXY || 
                   process.env.https_proxy || 
                   process.env.HTTP_PROXY || 
                   process.env.http_proxy ||
                   process.env.ALL_PROXY ||
                   process.env.all_proxy;

  if (!proxyUrl) {
    // 没有代理设置，返回空对象
    cachedProxyUrl = null;
    cachedDispatcher = null;
    cachedHttpsAgent = null;
    return {};
  }

  if (cachedProxyUrl === proxyUrl && cachedDispatcher && cachedHttpsAgent) {
    return {
      dispatcher: cachedDispatcher,
      agent: cachedHttpsAgent,
    };
  }

  try {
    // 创建 https-proxy-agent 实例
    const dispatcher = new ProxyAgent(proxyUrl);
    const agent = new HttpsProxyAgent(proxyUrl);
    cachedProxyUrl = proxyUrl;
    cachedDispatcher = dispatcher;
    cachedHttpsAgent = agent;
    
    return {
      dispatcher,
      agent: agent as any, // Node.js 传统 http/https 请求的 agent 选项
    };
  } catch (error) {
    console.warn('Failed to create proxy agent:', error);
    // 如果代理配置失败，继续使用直连
    return {};
  }
}

/**
 * 带代理支持的 fetch 函数
 * @param url 请求URL
 * @param options fetch选项
 * @returns Response对象
 */
export async function fetchWithProxy(url: string, options: RequestInit = {}): Promise<Response> {
  const proxyOptions = getProxyFetchOptions();
  
  return fetch(url, {
    ...options,
    ...proxyOptions,
  });
}
