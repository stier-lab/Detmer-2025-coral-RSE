import React from 'react';
import { clsx } from 'clsx';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ variant = 'primary', size = 'md', className, children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={clsx(
          // Base styles
          'inline-flex items-center justify-center rounded-lg font-medium transition-all focus-ring disabled:opacity-50 disabled:cursor-not-allowed',

          // Variant styles
          {
            'bg-primary-500 text-white hover:bg-primary-600 active:bg-primary-700 shadow-sm': variant === 'primary',
            'bg-gray-100 text-gray-900 hover:bg-gray-200 active:bg-gray-300': variant === 'secondary',
            'border-2 border-primary-500 text-primary-600 hover:bg-primary-50 active:bg-primary-100': variant === 'outline',
            'text-gray-700 hover:bg-gray-100 active:bg-gray-200': variant === 'ghost',
          },

          // Size styles
          {
            'px-3 py-1.5 text-sm': size === 'sm',
            'px-4 py-2 text-base': size === 'md',
            'px-6 py-3 text-lg': size === 'lg',
          },

          className
        )}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = 'Button';
