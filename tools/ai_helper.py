import os
import sys
from anthropic import Anthropic


def review_code(file_path, api_key=None):
    """
    Review a code file using Claude AI.

    Args:
        file_path: Path to the code file to review
        api_key: Anthropic API key (optional, will use ANTHROPIC_API_KEY env var if not provided)

    Returns:
        The AI's review as a string
    """
    if api_key is None:
        api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not api_key:
            raise ValueError("API key not provided. Set ANTHROPIC_API_KEY environment variable or pass api_key parameter.")

    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    with open(file_path, 'r', encoding='utf-8') as f:
        code_content = f.read()

    client = Anthropic(api_key=api_key)

    prompt = f"""Please review the following code file and provide feedback on:
1. Code quality and best practices
2. Potential bugs or issues
3. Security concerns
4. Performance improvements
5. Readability and maintainability

File: {os.path.basename(file_path)}

```
{code_content}
```

Please provide a detailed but concise review."""

    message = client.messages.create(
        model="claude-sonnet-4-5-20250929",
        max_tokens=4096,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return message.content[0].text


def main():
    if len(sys.argv) < 2:
        print("Usage: python ai_helper.py <file_path> [api_key]")
        print("\nReviews a code file using Claude AI")
        print("\nExample:")
        print("  python ai_helper.py script.py")
        print("  python ai_helper.py script.py your-api-key-here")
        sys.exit(1)

    file_path = sys.argv[1]
    api_key = sys.argv[2] if len(sys.argv) > 2 else None

    try:
        print(f"Reviewing {file_path}...\n")
        review = review_code(file_path, api_key)
        print(review)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
