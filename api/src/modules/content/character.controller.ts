import { Request, Response } from 'express';
import { characterService } from './character.service';
import { sendSuccess, sendError } from '../../shared/utils/response.util';
import { createCharacterSchema, updateCharacterSchema } from './character.validator';

export class CharacterController {

  async listActive(_req: Request, res: Response) {
    try {
      const characters = await characterService.listActiveCharacters();
      return sendSuccess(res, { characters, total: characters.length });
    } catch {
      return sendError(res, 'Erro ao buscar personagens', 'INTERNAL_ERROR', 500);
    }
  }

  async listAdmin(req: Request, res: Response) {
    try {
      const { is_active, rarity, is_sacred, search, page, limit } = req.query;
      const result = await characterService.listCharacters({
        is_active:  is_active  !== undefined ? is_active  === 'true' : undefined,
        is_sacred:  is_sacred  !== undefined ? is_sacred  === 'true' : undefined,
        rarity:     rarity     as string | undefined,
        search:     search     as string | undefined,
        page:       page  ? Number(page)  : 1,
        limit:      limit ? Number(limit) : 50,
      });
      return sendSuccess(res, result);
    } catch {
      return sendError(res, 'Erro ao buscar personagens', 'INTERNAL_ERROR', 500);
    }
  }

  async getStats(_req: Request, res: Response) {
    try {
      const stats = await characterService.getStats();
      return sendSuccess(res, stats);
    } catch {
      return sendError(res, 'Erro ao buscar estatísticas', 'INTERNAL_ERROR', 500);
    }
  }

  async getById(req: Request, res: Response) {
    try {
      const character = await characterService.getCharacterById(req.params.id);
      return sendSuccess(res, character);
    } catch (err: unknown) {
      if ((err as Error).message === 'CHARACTER_NOT_FOUND')
        return sendError(res, 'Personagem não encontrado', 'CHARACTER_NOT_FOUND', 404);
      return sendError(res, 'Erro interno', 'INTERNAL_ERROR', 500);
    }
  }

  async create(req: Request, res: Response) {
    try {
      const parsed = createCharacterSchema.safeParse(req.body);
      if (!parsed.success)
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      const character = await characterService.createCharacter(parsed.data);
      return sendSuccess(res, character, 'Personagem criado com sucesso', 201);
    } catch {
      return sendError(res, 'Erro ao criar personagem', 'INTERNAL_ERROR', 500);
    }
  }

  async update(req: Request, res: Response) {
    try {
      const parsed = updateCharacterSchema.safeParse(req.body);
      if (!parsed.success)
        return sendError(res, parsed.error.errors[0].message, 'VALIDATION_ERROR', 422);
      const character = await characterService.updateCharacter(req.params.id, parsed.data);
      return sendSuccess(res, character, 'Personagem atualizado com sucesso');
    } catch (err: unknown) {
      if ((err as Error).message === 'CHARACTER_NOT_FOUND')
        return sendError(res, 'Personagem não encontrado', 'CHARACTER_NOT_FOUND', 404);
      return sendError(res, 'Erro ao atualizar personagem', 'INTERNAL_ERROR', 500);
    }
  }

  async delete(req: Request, res: Response) {
    try {
      await characterService.deleteCharacter(req.params.id);
      return sendSuccess(res, null, 'Personagem removido com sucesso');
    } catch (err: unknown) {
      const msg = (err as Error).message;
      if (msg === 'CHARACTER_NOT_FOUND')
        return sendError(res, 'Personagem não encontrado', 'CHARACTER_NOT_FOUND', 404);
      if (msg === 'CANNOT_DELETE_SACRED')
        return sendError(res, 'Personagens sagrados não podem ser excluídos', 'CANNOT_DELETE_SACRED', 403);
      return sendError(res, 'Erro ao remover personagem', 'INTERNAL_ERROR', 500);
    }
  }

  async toggleActive(req: Request, res: Response) {
    try {
      const character = await characterService.toggleActive(req.params.id);
      const status = character.is_active ? 'ativado' : 'desativado';
      return sendSuccess(res, character, `Personagem ${status} com sucesso`);
    } catch (err: unknown) {
      if ((err as Error).message === 'CHARACTER_NOT_FOUND')
        return sendError(res, 'Personagem não encontrado', 'CHARACTER_NOT_FOUND', 404);
      return sendError(res, 'Erro ao alterar status', 'INTERNAL_ERROR', 500);
    }
  }

  async seed(_req: Request, res: Response) {
    try {
      const result = await characterService.runSeed();
      return sendSuccess(
        res, result,
        `Seed concluído: ${result.created} criados, ${result.updated} atualizados`,
        201,
      );
    } catch {
      return sendError(res, 'Erro ao executar seed', 'INTERNAL_ERROR', 500);
    }
  }
}

export const characterController = new CharacterController();
