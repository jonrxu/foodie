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
            payload = {
                "tool": "create-shopping-list",
                "parameters": {
                    "title": title,
                    "items": [
                        {
                            "name": item.name,
                            "quantity": item.quantity,
                            "note": item.notes,
                            "store": store,
                        }
                        for item in items
                        if item.isSelected
                    ],
                },
            }
            response = httpx.post(
                self._mcp_url,
                json=payload,
                headers={
                    "Authorization": f"Bearer {self._api_key}",
                    "Content-Type": "application/json",
                },
                timeout=10.0,
            )
            response.raise_for_status()
            result = response.json().get("result", {})
            return InstacartListResult(
                list_id=result.get("listID", ""),
                share_url=result.get("shareURL", ""),
                item_count=result.get("itemCount", len(items)),
            )
        except Exception as exc:
            logger.warning("Instacart MCP call failed: %s", exc)
            return None
