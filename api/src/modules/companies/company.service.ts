import { CompanyModel, ICompany } from './company.model';
import { UserModel } from '../users/user.model';
import mongoose from 'mongoose';

export class CompanyService {
  async createCompany(data: Partial<ICompany>): Promise<ICompany> {
    const invite_code = Math.random().toString(36).substring(2, 8).toUpperCase();
    
    // Limits
    const limits = { free: 30, basic: 100, professional: 500, enterprise: 999999 };
    const max_members = limits[data.plan as keyof typeof limits] || 30;

    const company = await CompanyModel.create({
      ...data,
      slug: data.name?.toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + invite_code.substring(0,3),
      invite_code,
      members_limit: max_members
    });

    return company;
  }

  async getCompanyStats(companyId: string): Promise<any> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const pipeline = [
      { $match: { company_id: new mongoose.Types.ObjectId(companyId), is_active: true } },
      { $group: {
        _id: null,
        total_members: { $sum: 1 },
        active_today: { $sum: { $cond: [{ $gte: ['$last_seen_at', today] }, 1, 0] } },
        average_streak: { $avg: '$streak_current' }
      }}
    ];

    const statsRaw = await UserModel.aggregate(pipeline);
    const stats = statsRaw[0] || { total_members: 0, active_today: 0, average_streak: 0 };

    return {
       overview: {
          total_members: stats.total_members,
          active_today: stats.active_today,
          average_streak: Math.round(stats.average_streak * 10) / 10
       }
    };
  }

  async addMember(companyId: string, userId: string): Promise<boolean> {
     const company = await CompanyModel.findById(companyId);
     if (!company) throw new Error('Company not found');

     const currentMembers = await UserModel.countDocuments({ company_id: companyId });
     if (currentMembers >= company.members_limit) {
         throw new Error('Limite do plano excedido');
     }

     await UserModel.findByIdAndUpdate(userId, { company_id: companyId });
     return true;
  }

  async joinByInviteCode(code: string, userId: string): Promise<any> {
     const company = await CompanyModel.findOne({ invite_code: code });
     if (!company) throw new Error('Código inválido');
     if (!company.allow_public_join) throw new Error('Entrada pública desativada');

     await this.addMember(company._id.toString(), userId);
     return company;
  }
}
