import Anthropic from "npm:@anthropic-ai/sdk";

const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY") });

Deno.serve(async (req) => {
    const { message } = await req.json();

    const response = await client.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 1000,
        system: "أنت مساعد تطبيق حكايتي لقصص الأطفال.",
        messages: [{ role: "user", content: message }]
    });

    return new Response(JSON.stringify({
        reply: response.content[0].text
    }), { headers: { "Content-Type": "application/json" } });
});