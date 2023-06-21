import { Redis } from "@upstash/redis/cloudflare";

export interface Env {
	UPSTASH_REDIS_REST_TOKEN: string;
	UPSTASH_REDIS_REST_URL: string;
}


export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const redis = Redis.fromEnv(env);

		if(request.method === "POST") {
			const data = await request.json() as any;
			const time = data.time;
			const value = data.value;
			const bucket = data.bucket;
			
			await redis.sadd(bucket, JSON.stringify({
				time, value
			}))

			return new Response(JSON.stringify({ time, value, bucket }));
		} else {
			// get set
			const data = new URL(request.url);
			const bucket = data.searchParams.get("bucket")!;
			const values = await redis.smembers(bucket);
			return new Response(JSON.stringify(values));
		}
	},
};


//{"time": 2,"value": 50.5, "bucket": "temperature"}