from __future__ import annotations

import logging
from dataclasses import dataclass

import httpx

from app.schemas.meals import CartItemPayload

logger = logging.getLogger(__name__)


@dataclass
class InstacartListResult:
    list_id: str
    share_url: str
    item_count: int


class InstacartClient:
    def __init__(self, api_key: str, mcp_url: str) -> None:
        self._api_key = api_key
        self._mcp_url = mcp_url

    def create_shopping_list(
        self,
        items: list[CartItemPayload],
        title: str,
        store: str = "GIANT",
    ) -> InstacartListResult | None:
        if not self._api_key:
            return None
        try:
            def _parse_qty(qty_str: str | None) -> float | None:
                """Parse '1.5 lb' → 1.5, '2 ct' → 2, None → None."""
                if not qty_str:
                    return None
                import re
                m = re.match(r"^\s*(\d+(?:\.\d+)?)", qty_str.strip())
                return float(m.group(1)) if m else None

            payload = {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "tools/call",
                "params": {
                    "name": "create-shopping-list",
                    "arguments": {
                        "title": title,
                        "lineItems": [
                            {
                                "name": item.name,
                                **({"quantity": _parse_qty(item.quantity)} if _parse_qty(item.quantity) else {}),
                                "displayText": item.quantity or "",
                            }
                            for item in items
                            if item.isSelected
                        ],
                    },
                },
            }
            response = httpx.post(
                self._mcp_url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "Content-Type": "application/json",
                },
                timeout=15.0,
            )
            response.raise_for_status()
            body = response.json()
            if "error" in body:
                logger.warning("Instacart MCP error: %s", body["error"])
                return None
            result = body.get("result", {})
            # MCP returns a content array with text blocks containing the share URL
            import re
            share_url = ""
            list_id = ""
            for block in result.get("content", []):
                if block.get("type") == "text":
                    text = block.get("text", "")
                    if not share_url:
                        m = re.search(r"https://[^\s]+instacart[^\s]+", text)
                        if m:
                            share_url = m.group(0).rstrip(".,)")
                    if not list_id:
                        m = re.search(r'"list_id"\s*:\s*"([^"]+)"', text)
                        if m:
                            list_id = m.group(1)
            return InstacartListResult(
                list_id=list_id,
                share_url=share_url,
                item_count=len(items),
            )
        except Exception as exc:
            logger.warning("Instacart MCP call failed: %s", exc)
            return None
