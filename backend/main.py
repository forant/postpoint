from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import OpenAI, APIError, AuthenticationError
import os
import json

app = FastAPI(title="PostPoint API")
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# MARK: - Models

class DebriefRequest(BaseModel):
    result: str
    score: str | None = None
    matchFormat: str
    biggestProblems: list[str]
    matchPattern: str
    opponentLevel: str
    context: str | None = None

class DebriefResponse(BaseModel):
    primaryIssue: str
    explanation: str
    nextMatchAdjustment: str

# MARK: - System Prompt

SYSTEM_PROMPT = """You are a highly perceptive tennis and pickleball coach.

Your job is to analyze a player's match using limited inputs and produce a sharp, specific, and actionable debrief.

Rules:
- Be concise but insightful
- Avoid generic advice
- Identify ONE primary issue that likely caused the result
- Explain WHY it mattered in the context of the match
- Give ONE clear adjustment for the next match
- If relevant, include a specific tactical suggestion

Context handling:
- You may be given additional context such as fatigue, stress, illness, or conditions
- Use this context to refine your analysis
- Do NOT let context become an excuse
- Even if context contributed, still identify a controllable adjustment

Tone:
- Direct, slightly opinionated, but constructive
- Sound like a smart coach, not a motivational speaker

Do NOT list multiple tips. Focus on the highest-leverage insight."""

# MARK: - Endpoint

@app.post("/debrief", response_model=DebriefResponse)
async def generate_debrief(req: DebriefRequest):
    user_prompt = build_user_prompt(req)

    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.7,
            max_tokens=500,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
        )
    except AuthenticationError:
        raise HTTPException(status_code=500, detail="OpenAI API key is invalid.")
    except APIError as e:
        raise HTTPException(status_code=502, detail=f"OpenAI error: {e.message}")

    content = completion.choices[0].message.content
    if not content:
        raise HTTPException(status_code=502, detail="Empty response from AI.")

    # Strip markdown fences if present
    cleaned = content.strip().removeprefix("```json").removeprefix("```").removesuffix("```").strip()

    try:
        data = json.loads(cleaned)
        return DebriefResponse(**data)
    except (json.JSONDecodeError, KeyError, TypeError):
        raise HTTPException(status_code=502, detail="Invalid JSON from AI.")


def build_user_prompt(req: DebriefRequest) -> str:
    lines = [
        f"Match result: {req.result}",
        f"Format: {req.matchFormat}",
    ]

    if req.score:
        lines.append(f"Score: {req.score}")

    issues = ", ".join(req.biggestProblems)
    lines.append(f"Biggest issue: {issues}")
    lines.append(f"Match pattern: {req.matchPattern}")
    lines.append(f"Opponent level: {req.opponentLevel}")
    lines.append(f"Additional context: {req.context or 'None'}")

    lines.append("")
    lines.append("Generate a short post-match debrief.")
    lines.append("")
    lines.append("""Return ONLY valid JSON in this exact shape:
{
  "primaryIssue": "short headline",
  "explanation": "2-4 sentence explanation",
  "nextMatchAdjustment": "one specific adjustment"
}""")

    return "\n".join(lines)


# MARK: - Health Check

@app.get("/health")
async def health():
    return {"status": "ok"}
