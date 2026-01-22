import React from 'react';
import { clsx } from 'clsx';

export interface SliderProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string;
  description?: string;
  showValue?: boolean;
  valueFormatter?: (value: number) => string;
  unit?: string;
}

export const Slider: React.FC<SliderProps> = ({
  label,
  description,
  showValue = true,
  valueFormatter,
  unit,
  className,
  id,
  value,
  ...props
}) => {
  const inputId = id || `slider-${label?.replace(/\s+/g, '-').toLowerCase()}`;

  const formatValue = (val: number) => {
    if (valueFormatter) return valueFormatter(val);
    if (unit) return `${val}${unit}`;
    return val.toString();
  };

  const currentValue = typeof value === 'string' ? parseFloat(value) : (typeof value === 'number' ? value : 0);

  return (
    <div className={clsx('flex flex-col gap-2', className)}>
      {label && (
        <div className="flex items-center justify-between">
          <label htmlFor={inputId} className="text-sm font-medium text-gray-700">
            {label}
          </label>
          {showValue && (
            <output
              htmlFor={inputId}
              className="text-sm font-semibold text-primary-600 min-w-[60px] text-right"
            >
              {formatValue(currentValue)}
            </output>
          )}
        </div>
      )}

      <input
        type="range"
        id={inputId}
        value={value}
        className={clsx(
          'w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer',
          'focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2',
          '[&::-webkit-slider-thumb]:appearance-none',
          '[&::-webkit-slider-thumb]:w-5',
          '[&::-webkit-slider-thumb]:h-5',
          '[&::-webkit-slider-thumb]:rounded-full',
          '[&::-webkit-slider-thumb]:bg-primary-500',
          '[&::-webkit-slider-thumb]:hover:bg-primary-600',
          '[&::-webkit-slider-thumb]:transition-colors',
          '[&::-webkit-slider-thumb]:shadow-md',
          '[&::-moz-range-thumb]:w-5',
          '[&::-moz-range-thumb]:h-5',
          '[&::-moz-range-thumb]:rounded-full',
          '[&::-moz-range-thumb]:bg-primary-500',
          '[&::-moz-range-thumb]:hover:bg-primary-600',
          '[&::-moz-range-thumb]:border-0',
          '[&::-moz-range-thumb]:transition-colors',
          '[&::-moz-range-thumb]:shadow-md'
        )}
        aria-describedby={description ? `${inputId}-description` : undefined}
        {...props}
      />

      {description && (
        <p id={`${inputId}-description`} className="text-xs text-gray-500">
          {description}
        </p>
      )}
    </div>
  );
};
