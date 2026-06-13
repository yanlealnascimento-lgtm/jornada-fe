import type { ComponentType, SVGAttributes } from "react";
import { Button } from "./ui/button";

interface EmptyStateProps {
  icon: ComponentType<SVGAttributes<SVGElement>>;
  title: string;
  description: string;
  actionText?: string;
  onAction?: () => void;
}

export function EmptyState({ icon: Icon, title, description, actionText, onAction }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center border rounded-lg border-dashed bg-gray-50/50 dark:bg-gray-800/20">
      <div className="flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 mb-4">
        <Icon className="w-6 h-6 text-primary" />
      </div>
      <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">{title}</h3>
      <p className="mt-1 mb-4 text-sm text-gray-500 max-w-sm">{description}</p>
      {actionText && onAction && (
        <Button onClick={onAction}>{actionText}</Button>
      )}
    </div>
  );
}
