import { isToday as fnsIsToday, isYesterday as fnsIsYesterday, startOfWeek, endOfWeek, format, isSameDay as fnsIsSameDay, differenceInDays } from 'date-fns';

export const isToday = (date: Date): boolean => {
  return fnsIsToday(date);
};

export const isYesterday = (date: Date): boolean => {
  return fnsIsYesterday(date);
};

export const isSameDay = (date1: Date, date2: Date): boolean => {
  return fnsIsSameDay(date1, date2);
};

export const getWeekKey = (): string => {
  return format(new Date(), "yyyy-'W'ww");
};

export const getStartOfWeek = (): Date => {
  return startOfWeek(new Date(), { weekStartsOn: 1 });
};

export const getEndOfWeek = (): Date => {
  return endOfWeek(new Date(), { weekStartsOn: 1 });
};

export const daysBetween = (d1: Date, d2: Date): number => {
  return differenceInDays(d1, d2);
};

export const getBrazilianDate = (): Date => {
  const date = new Date();
  const options = { timeZone: 'America/Sao_Paulo' };
  return new Date(date.toLocaleString('en-US', options));
};
