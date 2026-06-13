import React from "react";
import { cn } from "../lib/utils";

interface StatusBadgeProps {
  status: "published" | "draft" | "inactive" | "coming_soon" | "active";
  className?: string;
}

const statusConfig = {
  published: { label: "Publicado", style: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-500 border-green-200" },
  active: { label: "Ativo", style: "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-500 border-green-200" },
  draft: { label: "Rascunho", style: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-400 border-gray-200" },
  inactive: { label: "Inativo", style: "bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-500 border-red-200" },
  coming_soon: { label: "Em breve", style: "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-500 border-blue-200" },
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status] || statusConfig.draft;

  return (
    <span
      className={cn(
        "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border",
        config.style,
        className
      )}
    >
      {config.label}
    </span>
  );
}
