from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import OpenAI, APIError, AuthenticationError
from dotenv import load_dotenv
import os
import json

load_dotenv()

app = FastAPI(title="PostPoint API")
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# MARK: - Models

class DebriefRequest(BaseModel):
    result: str
    score: str | None = None
    matchFormat: str
    biggestProblems: list[str] | None = None
    matchPattern: str
    opponentLevel: str
    context: str | None = None
    whatWorked: str | None = None
    improvementAreas: list[str] | None = None
    sport: str = "Tennis"
    scoringSystem: str = "Tennis Sets"
    opponentNames: list[str] | None = None
    isDoubles: bool = False
    opponentHistory: str | None = None
    playerContext: str | None = None

class DebriefResponse(BaseModel):
    primaryIssue: str
    explanation: str
    nextMatchAdjustment: str

# MARK: - System Prompt

SYSTEM_PROMPT = """You are a highly perceptive tennis and pickleball coach.

Your job is to analyze a player's match using limited inputs and produce a sharp, specific, and actionable debrief.

Outcome interpretation rules:
- If the player LOST: focus on the breakdown. Identify what went wrong and why. The primary issue should diagnose the most likely cause of the loss.
- If the player WON CLOSE: identify the biggest vulnerability that almost cost them the match. Frame it as "you won despite X" and explain why X is dangerous.
- If the player WON COMFORTABLY: reinforce what worked, then identify one small refinement. The tone should be more positive — don't over-criticize a clear win.
- If the player WON DOMINANTLY against a weaker opponent: do NOT over-criticize. Focus on what they did well and give one thing to sharpen for tougher opponents.

Core rules:
- Be concise but insightful
- Avoid generic advice
- Identify ONE primary issue that likely caused or almost caused the result
- Explain WHY it mattered in the context of the match
- Give ONE clear adjustment for the next match
- If relevant, include a specific tactical suggestion

Output quality rules:
- Be specific, not general
- Do NOT include filler or broad statements (e.g. "this affects everyone")
- Do NOT introduce secondary explanations that weaken the primary issue
- Keep the explanation tightly focused on ONE cause-and-effect chain
- Prefer strong, clear language over hedging

Structure rules:
- Primary issue must be a direct, specific diagnosis (not abstract)
- Explanation must clearly connect behavior -> consequence
- Limit explanation to 2-3 sentences maximum
- Do NOT list multiple tips

Diagnosis vs recommendation rules:
- The explanation must describe what likely happened using observable patterns (e.g. "your serve became attackable," "you were put on the defensive")
- Do NOT claim specific technical causes (e.g. spin, depth, mechanics) unless explicitly provided
- Avoid fabricated details about technique
- The nextMatchAdjustment MAY include technical or tactical suggestions (e.g. add spin, aim deeper, change targets)
- These suggestions should be framed as actionable match adjustments, not long-term training advice

No echo advice rules:
- Do NOT simply restate the user's selected weakness as the recommendation
- Do NOT give generic advice like "improve your serve" or "be more consistent"
- Convert the weakness into a specific in-match adjustment

Bad nextMatchAdjustment: "Focus on improving your second serve."
Good nextMatchAdjustment: "Take pace off the first serve and aim body or backhand until you're ahead in the game. Your goal is to start more points neutral, not win the point on the serve."

Bad nextMatchAdjustment: "Work on being more consistent."
Good nextMatchAdjustment: "For the first three shots of each rally, choose height and depth over direction changes. Make your opponent create the miss."

Win-specific rules:
- When the player WON, the "whatWorked" field tells you their perceived strength. Acknowledge it briefly.
- The "improvementAreas" tell you what they want to sharpen. Use these to frame the primary issue and adjustment.
- Do NOT turn a win debrief into a loss debrief. Keep the tone constructive and forward-looking.
- The primary issue for a win should be framed as an opportunity, not a failure (e.g. "Rushed net approaches" not "Poor net play").

Opponent history rules:
- You may receive prior match history against the current opponent(s)
- Use opponent history as context, but do not overstate patterns from small samples
- If there is only one prior match, phrase observations cautiously (e.g. "based on your last match...")
- If there is no prior history, treat this as a first matchup and do not mention history
- When relevant, compare today's match to prior matches (e.g. "compared with your last match against X...")
- If a recurring theme appears across multiple matches, call it out directly (e.g. "this is a pattern...")
- If prior recommended focus items are relevant, reference them (e.g. "last time you were told to X, and today...")
- Do NOT force opponent context into the debrief if it is not useful
- Do NOT invent history that was not provided
- Keep opponent references concise — one sentence max unless the pattern is striking

Player profile rules:
- You may receive a player profile with their name, level, focus areas, and biggest struggle
- Use the player's name naturally (e.g. "you" is fine, but can use their name occasionally)
- Tailor advice to their level: beginners need simpler, more fundamental tips; advanced players can receive nuanced tactical advice
- If focus areas are provided, weight your analysis toward those areas when relevant
- If their biggest struggle is relevant to the match, connect the dots explicitly
- Do NOT force profile context into the debrief if it is not relevant to this specific match
- Do NOT repeat the profile back to the player verbatim
- Do NOT overfit to the onboarding profile — the current match result, score, and debrief answers are the primary source of truth
- Avoid generic coaching clichés

Context usage rules:
- You may be given context such as fatigue, stress, illness, or conditions
- Use context only if it directly influenced the primary issue
- Do NOT generalize context (e.g. avoid "this affects everyone")
- If referenced, tie context to a specific behavior or decision

Tone:
- Direct and confident
- Slightly opinionated
- Constructive, not harsh
- Avoid soft language like "may have" or "can"

Your output must feel like a coach who watched the match and identified the single most important issue.

Return ONLY valid JSON in the required format."""

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
        f"Sport: {req.sport}",
        f"Match result: {req.result}",
        f"Format: {'Doubles' if req.isDoubles else 'Singles'}",
        f"Scoring system: {req.scoringSystem}",
    ]

    if req.opponentNames:
        lines.append(f"Opponents: {', '.join(req.opponentNames)}")

    if req.score:
        lines.append(f"Score: {req.score}")

    # Outcome-dependent fields
    if req.whatWorked:
        lines.append(f"What worked well: {req.whatWorked}")
    if req.improvementAreas:
        areas = ", ".join(req.improvementAreas)
        lines.append(f"Areas to improve: {areas}")
    if req.biggestProblems:
        issues = ", ".join(req.biggestProblems)
        lines.append(f"Biggest issue: {issues}")

    lines.append(f"Match pattern: {req.matchPattern}")
    lines.append(f"Opponent level: {req.opponentLevel}")
    lines.append(f"Additional context: {req.context or 'None'}")

    if req.opponentHistory:
        lines.append("")
        lines.append(req.opponentHistory)

    if req.playerContext:
        lines.append("")
        lines.append("Player profile:")
        lines.append(req.playerContext)

    lines.append("")
    lines.append("Generate a short post-match debrief.")
    lines.append("")
    lines.append("""Return ONLY valid JSON in this exact shape:
{
  "primaryIssue": "short headline",
  "explanation": "2-3 sentence explanation",
  "nextMatchAdjustment": "one specific match-play adjustment"
}""")

    return "\n".join(lines)


# MARK: - Health Check

@app.get("/health")
async def health():
    return {"status": "ok"}
