import React from "react";
import { cn } from "../lib/utils";

export type RarityType = "common" | "uncommon" | "rare" | "epic" | "special";

interface RarityBadgeProps {
  rarity: RarityType;
  className?: string;
}

const rarityConfig = {
  common: { label: "Comum", style: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400 border-gray-200" },
  uncommon: { label: "Incomum", style: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-500 border-green-200" },
  rare: { label: "Raro", style: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-500 border-blue-200" },
  epic: { label: "Épico", style: "bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-500 border-purple-200" },
  special: { label: "Especial", style: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-600 border-yellow-300" },
};

export function RarityBadge({ rarity, className }: RarityBadgeProps) {
  const config = rarityConfig[rarity] || rarityConfig.common;

  return (
    <span
      className={cn(
        "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border uppercase tracking-wider",
        config.style,
        className
      )}
    >
      {config.label}
    </span>
  );
}
