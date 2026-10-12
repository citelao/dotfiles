/**
 * Session rename extension.
 *
 * Lets pi name itself. Two ways to use it:
 *
 *   /rename <name>   Set the session name explicitly.
 *   /rename          Ask the active model to generate a name from the
 *                    current conversation.
 *
 * It also auto-names a session the first time a turn completes, so long as
 * the session does not already have a name. Set PI_RENAME_NO_AUTO=1 to
 * disable the automatic behavior and keep only the /rename command.
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import type {
	ExtensionAPI,
	ExtensionCommandContext,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type ContentBlock = {
	type?: string;
	text?: string;
	name?: string;
	arguments?: Record<string, unknown>;
};

type SessionEntry = {
	type: string;
	message?: {
		role?: string;
		content?: unknown;
	};
};

const extractText = (content: unknown): string[] => {
	if (typeof content === "string") {
		return [content];
	}
	if (!Array.isArray(content)) {
		return [];
	}
	const parts: string[] = [];
	for (const part of content) {
		if (!part || typeof part !== "object") {
			continue;
		}
		const block: ContentBlock = part;
		if (block.type === "text" && typeof block.text === "string") {
			parts.push(block.text);
		}
	}
	return parts;
};

const buildConversationText = (entries: SessionEntry[]): string => {
	const sections: string[] = [];
	for (const entry of entries) {
		if (entry.type !== "message" || !entry.message?.role) {
			continue;
		}
		const role = entry.message.role;
		if (role !== "user" && role !== "assistant") {
			continue;
		}
		const text = extractText(entry.message.content).join("\n").trim();
		if (text.length > 0) {
			sections.push(`${role === "user" ? "User" : "Assistant"}: ${text}`);
		}
	}
	// Keep the prompt small: the opening exchange is enough to name a session.
	return sections.slice(0, 6).join("\n\n");
};

const buildNamePrompt = (conversationText: string): string =>
	[
		"Generate a short, descriptive title for this conversation.",
		"Rules:",
		"- 3 to 6 words, Title Case.",
		"- No surrounding quotes, punctuation, or trailing period.",
		"- Describe the task or topic, not the participants.",
		"Reply with the title only.",
		"",
		"<conversation>",
		conversationText,
		"</conversation>",
	].join("\n");

const sanitizeName = (raw: string): string =>
	raw
		.trim()
		.split("\n")[0]
		.replace(/^["'`]+|["'`]+$/g, "")
		.replace(/[.\s]+$/, "")
		.slice(0, 80)
		.trim();

const generateName = async (
	ctx: ExtensionContext | ExtensionCommandContext,
): Promise<string | undefined> => {
	const branch: SessionEntry[] = ctx.sessionManager.getBranch();
	const conversationText = buildConversationText(branch);
	if (!conversationText) {
		return undefined;
	}

	const model = ctx.model;
	if (!model || !ctx.modelRegistry.hasConfiguredAuth(model)) {
		return undefined;
	}

	const response = await ctx.modelRegistry.complete(
		model,
		{
			messages: [
				{
					role: "user" as const,
					content: [{ type: "text" as const, text: buildNamePrompt(conversationText) }],
					timestamp: Date.now(),
				},
			],
		},
		{
			reasoningEffort: "low",
			cacheRetention: "none",
			sessionId: uuidv7(),
		},
	);

	const text = response.content
		.filter((c): c is { type: "text"; text: string } => c.type === "text")
		.map((c) => c.text)
		.join(" ");

	const name = sanitizeName(text);
	return name.length > 0 ? name : undefined;
};

export default function (pi: ExtensionAPI) {
	pi.registerCommand("rename", {
		description: "Rename the session (usage: /rename [name] — no name asks the model)",
		handler: async (args, ctx) => {
			const explicit = args.trim();
			if (explicit) {
				pi.setSessionName(explicit);
				ctx.ui.notify(`Session named: ${explicit}`, "info");
				return;
			}

			ctx.ui.notify("Generating session name...", "info");
			const name = await generateName(ctx);
			if (name) {
				pi.setSessionName(name);
				ctx.ui.notify(`Session named: ${name}`, "info");
			} else {
				ctx.ui.notify("Could not generate a name", "warning");
			}
		},
	});

	if (process.env.PI_RENAME_NO_AUTO === "1") {
		return;
	}

	let autoNamed = false;
	pi.on("turn_end", async (_event, ctx) => {
		if (autoNamed || pi.getSessionName()) {
			return;
		}
		autoNamed = true;
		const name = await generateName(ctx);
		if (name && !pi.getSessionName()) {
			pi.setSessionName(name);
			ctx.ui.notify(`Session named: ${name}`, "info");
		}
	});
}
