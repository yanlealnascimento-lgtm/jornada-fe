import { Response } from 'express';
import { ApiResponse, PaginationMeta } from '../types';

export const sendSuccess = <T>(res: Response, data: T, message = 'Success', status = 200) => {
  const response: ApiResponse<T> = {
    success: true,
    data,
    message,
  };
  return res.status(status).json(response);
};

export const sendError = (res: Response, message: string, error = 'ERROR', status = 400) => {
  const response: ApiResponse = {
    success: false,
    error,
    message,
  };
  return res.status(status).json(response);
};

export const sendPaginated = <T>(res: Response, data: T[], meta: PaginationMeta, status = 200) => {
  const response: ApiResponse<T[]> = {
    success: true,
    data,
    pagination: meta,
  };
  return res.status(status).json(response);
};
