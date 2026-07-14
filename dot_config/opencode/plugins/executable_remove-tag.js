export default async function RemoveClaudeBragPlugin(ctx) {
    return {
        "experimental.chat.system.transform": async (input, output) => {
            if (output.system.length < 2) return;

            const targetText = "the best coding agent on the planet.";
            const original = output.system[1];

            if (!original || !original.includes(targetText)) return;

            // We need to prepend anything random
            output.system[1] =
                "Greetings from the coding assistant.\n\n" + original;

            // Remove the bragging phrase
            output.system[1] = output.system[1].replace(
                /You are (OpenCode|Claude Code), the best coding agent on the planet\.\n\n/,
                "You are $1.\n\n",
            );
        },
    };
}
